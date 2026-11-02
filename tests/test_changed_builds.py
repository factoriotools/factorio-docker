"""Incremental release selection and the actual publishing workflow shell logic."""

import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
BASE = {
    "2.0.77": {"sha256": "stable-sum", "tags": ["stable", "stable-2.0.77", "2.0.77"]},
    "2.1.23": {"sha256": "experimental-sum", "sha256_arm64": "arm-sum", "tags": ["latest", "2.1.23"]},
}


def build_module():
    spec = importlib.util.spec_from_file_location("build_changed", ROOT / "build.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ChangedBuildTests(unittest.TestCase):
    def setUp(self):
        self.build = build_module()

    def test_unchanged_and_removed_aliases_do_not_rebuild(self):
        info = copy.deepcopy(BASE["2.1.23"])
        self.assertFalse(self.build.release_changed("2.1.23", info, BASE))
        info["tags"].remove("latest")
        self.assertFalse(self.build.release_changed("2.1.23", info, BASE))

    def test_new_versions_archives_and_added_tags_rebuild(self):
        info = copy.deepcopy(BASE["2.1.23"])
        self.assertTrue(self.build.release_changed("2.1.24", info, BASE))
        for key in ("sha256", "sha256_arm64"):
            changed = {**info, key: "new-sum"}
            self.assertTrue(self.build.release_changed("2.1.23", changed, BASE))
        del info["sha256_arm64"]
        self.assertTrue(self.build.release_changed("2.1.23", info, BASE))
        info = copy.deepcopy(BASE["2.1.23"])
        info["tags"].append("stable")
        self.assertTrue(self.build.release_changed("2.1.23", info, BASE))

    def test_experimental_update_does_not_rebuild_stable_in_either_variant(self):
        data = copy.deepcopy(BASE)
        data["2.1.24"] = data.pop("2.1.23")
        data["2.1.24"]["tags"] = ["latest", "2.1.24"]
        for flags, count in (([], 1), (["--rootless"], 1), (["--both"], 2), (["--both", "--only-stable-latest"], 2)):
            with self.subTest(flags=flags), patch.object(self.build.json, "load", return_value=data), \
                 patch.object(self.build, "load_previous_buildinfo", return_value=BASE), \
                 patch.object(self.build, "build_and_push") as build, \
                 patch("sys.argv", ["build.py", "--changed-from", "previous", *flags]):
                self.build.main()
                self.assertEqual(build.call_count, count)
                self.assertEqual({call.args[1] for call in build.call_args_list}, {"2.1.24"})

    def test_no_changes_do_not_login_or_build(self):
        with patch.object(self.build.json, "load", return_value=BASE), \
             patch.object(self.build, "load_previous_buildinfo", return_value=BASE), \
             patch.object(self.build, "login") as login, \
             patch.object(self.build, "build_and_push") as build, \
             patch("sys.argv", ["build.py", "--changed-from", "previous", "--both", "--push-tags"]):
            self.build.main()
            login.assert_not_called()
            build.assert_not_called()

    def test_invalid_baseline_fails_before_building(self):
        with patch.object(self.build.json, "load", return_value=BASE), \
             patch.object(self.build, "load_previous_buildinfo", side_effect=ValueError("invalid baseline")), \
             patch.object(self.build, "build_and_push") as build, \
             patch("sys.argv", ["build.py", "--changed-from", "bad"]), \
             self.assertRaises(SystemExit) as error:
            self.build.main()
        self.assertEqual(error.exception.code, 2)
        build.assert_not_called()


class BuildWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        (self.work / "docker").mkdir()
        (self.work / "docker/Dockerfile").write_text("FROM scratch\n")
        (self.work / "buildinfo.json").write_text(json.dumps(BASE))
        build = self.work / "build.py"
        build.write_text('#!/usr/bin/env python3\nimport json,sys\nfrom pathlib import Path\nPath("build-args.json").write_text(json.dumps(sys.argv[1:]))\n')
        build.chmod(0o755)
        self.git("init", "--quiet")
        self.commit()
        self.before = self.git("rev-parse", "HEAD").stdout.strip()

    def git(self, *args):
        return subprocess.run(["git", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", *args],
                              cwd=self.work, check=True, capture_output=True, text=True)

    def commit(self):
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "fixture")

    def run_workflow(self, previous):
        workflow = (ROOT / ".github/workflows/docker-build.yml").read_text()
        script = textwrap.dedent(workflow.rsplit("        run: |\n", 1)[1])
        result = subprocess.run(["bash", "-e", "-c", script], cwd=self.work,
                                env={**os.environ, "PREVIOUS_SHA": previous}, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads((self.work / "build-args.json").read_text())

    def test_metadata_only_update_uses_baseline(self):
        (self.work / "buildinfo.json").write_text("{}")
        self.commit()
        args = self.run_workflow(self.before)
        self.assertEqual(args[-2:], ["--changed-from", self.before])
        module = build_module()
        module.__file__ = str(self.work / "build.py")
        self.assertEqual(module.load_previous_buildinfo(self.before), BASE)

    def test_runtime_change_forces_full_rebuild(self):
        (self.work / "docker/Dockerfile").write_text("FROM scratch\n# runtime changed\n")
        self.commit()
        self.assertNotIn("--changed-from", self.run_workflow(self.before))

    def test_manual_or_missing_baseline_rebuilds_all(self):
        for previous in ("", "0" * 40):
            self.assertNotIn("--changed-from", self.run_workflow(previous))

    def test_scheduled_update_passes_before_and_after_commits(self):
        update = (ROOT / ".github/workflows/update.yml").read_text()
        self.assertIn("previous_sha: ${{ needs.check.outputs.before_sha }}", update)
        self.assertIn("checkout_ref: ${{ needs.check.outputs.head_sha }}", update)
        self.assertIn('echo "sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"', update)
        workflow = (ROOT / ".github/workflows/docker-build.yml").read_text()
        self.assertIn("ref: ${{ inputs.checkout_ref || github.sha }}", workflow)
        self.assertIn("fetch-depth: 0", workflow)


if __name__ == "__main__":
    unittest.main()
