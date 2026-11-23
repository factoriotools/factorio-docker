"""Regression tests: python3 -m unittest discover -s tests -v."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class UpdateTests(unittest.TestCase):
    def run_update(self, stable, experimental, arm_versions, current=None):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            bin_dir = work / "bin"
            bin_dir.mkdir()
            (work / "docker").mkdir()
            (work / "README.md").write_text(
                "<!-- start autogeneration tags -->\nold\n<!-- end autogeneration tags -->\n"
            )
            (work / "buildinfo.json").write_text(json.dumps(current or {
                "2.0.76": {"sha256": "old", "tags": ["stable", "latest"]}
            }))
            releases = {"stable": {"headless": stable}, "experimental": {"headless": experimental}}
            sums = []
            for version in sorted({stable, experimental}):
                # Both historical and new upstream archive names remain supported.
                name = "factorio_headless_x64" if version.startswith("2.0.") else "factorio-headless_linux"
                sums.append(f"{'b' * 64}  {name}_{version}.tar.xz")
                if version in arm_versions:
                    sums.append(f"{'a' * 64}  factorio-headless_linux-arm64_{version}.tar.xz")
            (work / "releases.json").write_text(json.dumps(releases))
            (work / "sums.txt").write_text("\n".join(sums) + "\n")
            commands = {
                "curl": '#!/bin/sh\ncase "$1" in *latest-releases) cat releases.json;; *sha256sums/) cat sums.txt;; *) exit 99;; esac\n',
                "git": '#!/bin/sh\nprintf "%s\\n" "$*" >> git-calls\n',
                "yq": '#!/bin/sh\nprintf "%s\\n" "${sov:-}${sha:-}${sha_arm64:-}" >> compose-args\n',
            }
            for name, contents in commands.items():
                command = bin_dir / name
                command.write_text(contents)
                command.chmod(0o755)
            env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}"}
            result = subprocess.run(["bash", str(ROOT / "update.sh")], cwd=work,
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result.stderr, "", result.stderr)
            data = json.loads((work / "buildinfo.json").read_text())
            compose = (work / "compose-args").read_text() if (work / "compose-args").exists() else ""
            published = (work / "git-calls").exists()
            return data, compose, published

    def test_release_transitions(self):
        cases = [
            ("2.0.77", "2.1.24", {"2.1.24"}),
            ("2.1.23", "2.1.24", {"2.1.23", "2.1.24"}),
            ("2.1.24", "2.1.24", {"2.1.24"}),
            ("2.0.77", "2.0.77", set()),
        ]
        for stable, experimental, arm in cases:
            with self.subTest(stable=stable, experimental=experimental):
                data, compose, published = self.run_update(stable, experimental, arm)
                self.assertEqual(set(data), {stable, experimental})
                self.assertIn("stable", data[stable]["tags"])
                self.assertIn("latest", data[experimental]["tags"])
                for version, info in data.items():
                    self.assertEqual(info["sha256"], "b" * 64)
                    self.assertEqual(info.get("sha256_arm64"), "a" * 64 if version in arm else None)
                self.assertIn("SHA256_ARM64=" + ("a" * 64 if stable in arm else "") + "\n", compose)
                self.assertTrue(published)

    def test_unchanged_versions_do_not_publish(self):
        current = {"2.1.24": {"sha256": "b" * 64, "sha256_arm64": "a" * 64,
                               "tags": ["stable", "latest"]}}
        data, compose, published = self.run_update("2.1.24", "2.1.24", {"2.1.24"}, current)
        self.assertEqual(data, current)
        self.assertEqual(compose, "")
        self.assertFalse(published)


class BuildTests(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location("factorio_build", ROOT / "build.py")
        self.build = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.build)

    def test_build_arguments(self):
        for multiarch in (False, True):
            for dockerfile in ("Dockerfile", "Dockerfile.rootless"):
                for arm_sha in (None, "a" * 64):
                    with self.subTest(multiarch=multiarch, dockerfile=dockerfile, arm_sha=arm_sha):
                        with patch.object(self.build, "build_singlearch") as single, \
                             patch.object(self.build, "build_and_push_multiarch") as multi:
                            self.build.build_and_push("b" * 64, "2.1.24", ["test"], False,
                                                      multiarch, dockerfile=dockerfile,
                                                      sha256_arm64=arm_sha)
                            call = (multi if multiarch else single).call_args
                            self.assertEqual(call.args[0], str(ROOT / "docker"))
                            args = call.args[1]
                            self.assertEqual(args[:2], ["-f", dockerfile])
                            self.assertIn("SHA256=" + "b" * 64, args)
                            self.assertEqual("SHA256_ARM64=" + "a" * 64 in args, bool(arm_sha))

    def test_main_passes_checksum_to_both_variants(self):
        data = {
            "2.0.77": {"sha256": "b" * 64, "tags": ["stable"]},
            "2.1.24": {"sha256": "c" * 64, "sha256_arm64": "a" * 64, "tags": ["latest"]},
        }
        with patch.object(self.build.json, "load", return_value=data), \
             patch.object(self.build, "build_and_push") as build, \
             patch("sys.argv", ["build.py", "--both"]):
            self.build.main()
        self.assertEqual(build.call_count, 4)
        for call in build.call_args_list:
            self.assertEqual(call.kwargs.get("sha256_arm64"), data[call.args[1]].get("sha256_arm64"))
        self.assertEqual(sum(call.kwargs.get("dockerfile") == "Dockerfile.rootless"
                             for call in build.call_args_list), 2)


if __name__ == "__main__":
    unittest.main()
