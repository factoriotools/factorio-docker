"""Exercise release selection with a local fake mod portal; no credentials/network."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "docker/files/update-mods.sh"
PAYLOAD = b"fixture mod archive"


def release(version, game, dependencies=None):
    info = {} if game is None else {"factorio_version": game}
    if dependencies is not None:
        info["dependencies"] = dependencies
    return {"version": version, "file_name": f"fixture_{version}.zip",
            "download_url": f"/download/fixture/{version}",
            "sha1": hashlib.sha1(PAYLOAD).hexdigest(), "info_json": info}


class ModVersionTests(unittest.TestCase):
    def check_selection(self, game, releases, expected):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            mods = root / "mods"
            mods.mkdir()
            (mods / "mod-list.json").write_text(json.dumps({"mods": [{"name": "fixture", "enabled": True}]}))
            old = mods / "fixture_0.0.1.zip"
            old.write_bytes(b"keep until a compatible update succeeds")
            for index, item in enumerate(releases):
                item["released_at"] = f"2026-01-{index + 1:02d}T00:00:00Z"
            (root / "metadata.json").write_text(json.dumps({"name": "fixture", "releases": releases}))
            curl = root / "curl"
            curl.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
root = Path(os.environ["FIXTURE_ROOT"])
args = sys.argv[1:]
if "/api/mods/fixture/full" in args[-1]:
    print((root / "metadata.json").read_text())
else:
    (root / "download.json").write_text(json.dumps(args))
    Path(args[args.index("-o") + 1]).write_bytes(b"fixture mod archive")
    print("200", end="")
''')
            curl.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "FIXTURE_ROOT": str(root)}
            result = subprocess.run(["bash", str(SCRIPT), game, str(mods), "test-user", "test-token", ""],
                                    env=env, capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            if expected is None:
                self.assertFalse((root / "download.json").exists(), result.stdout + result.stderr)
                self.assertEqual(old.read_bytes(), b"keep until a compatible update succeeds")
                self.assertIn("Not compatible", result.stdout)
            else:
                self.assertEqual(sorted(p.name for p in mods.glob("*.zip")), [f"fixture_{expected}.zip"],
                                 result.stdout + result.stderr)
                self.assertEqual((mods / f"fixture_{expected}.zip").read_bytes(), PAYLOAD)
                self.assertIn(f"/download/fixture/{expected}?", json.loads((root / "download.json").read_text())[-1])

    def test_reject_older_and_newer_game_branches(self):
        self.check_selection("2.1.24", [release("1.0.0", "2.1"), release("2.0.0", "2.0"),
                                       release("3.0.0", "1.1"), release("4.0.0", "3.0")], "1.0.0")
        self.check_selection("2.0.77", [release("1.0.0", "1.1"), release("2.0.0", "2.1")], None)

    def test_same_branch_selects_newest_release(self):
        self.check_selection("2.1.24", [release("1.0.0", "2.1"), release("1.1.0", "2.1")], "1.1.0")

    def test_legacy_018_exception_is_only_for_10(self):
        self.check_selection("1.0.0", [release("1.0.0", "0.18")], "1.0.0")
        for game in ("1.1.110", "2.0.77", "0.17.79"):
            with self.subTest(game=game):
                self.check_selection(game, [release("1.0.0", "0.18")], None)

    def test_missing_factorio_version_defaults_to_012(self):
        self.check_selection("0.12.35", [release("1.0.0", None)], "1.0.0")
        self.check_selection("2.1.24", [release("1.0.0", None)], None)

    def test_base_patch_requirement_does_not_download_newer_requirement(self):
        self.check_selection("2.0.15", [release("1.0.0", "2.0", ["base >= 2.0.10"]),
                                       release("1.1.0", "2.0", ["base >= 2.0.18"])], "1.0.0")
        self.check_selection("2.0.15", [release("1.1.0", "2.0", ["base >= 2.0.18"])], None)


if __name__ == "__main__":
    unittest.main()
