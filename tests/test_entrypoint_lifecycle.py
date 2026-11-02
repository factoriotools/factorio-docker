"""Entrypoint lifecycle regressions using the existing isolated container fixture."""

import json
from pathlib import Path
import unittest

import test_config_paths as fixtures


class EntrypointLifecycleTests(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.ConfigPathTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)

    def args(self):
        return [json.loads(line) for line in self.fixture.calls.read_text().splitlines()]

    def test_named_save_survives_first_start_and_restart(self):
        f = self.fixture
        for script in fixtures.ENTRYPOINTS[:2]:
            name = script + " world"
            overrides = {"SAVE_NAME": name, "LOAD_LATEST_SAVE": "false"}
            # Each variant starts with an empty saves directory.
            saves = Path(f.env["SAVES"])
            saves.mkdir(exist_ok=True)
            for path in saves.iterdir():
                path.unlink()
            f.run_script(script, overrides)
            calls = self.args()
            self.assertIn("--create", calls[0])
            expected = str(saves / (name + ".zip"))
            self.assertEqual(calls[0][calls[0].index("--create") + 1], expected)
            self.assertEqual(calls[-1][calls[-1].index("--start-server") + 1], expected)
            f.run_script(script, overrides)
            self.assertEqual(len(self.args()), 1)
            self.assertEqual(self.args()[0][self.args()[0].index("--start-server") + 1], expected)

    def test_zip_suffix_and_absolute_save_paths(self):
        f = self.fixture
        for script in fixtures.ENTRYPOINTS[:2]:
            for name in ("my world.zip", str(f.work / "absolute world.zip")):
                with self.subTest(script=script, name=name):
                    f.run_script(script, {"SAVE_NAME": name, "GENERATE_NEW_SAVE": "true", "LOAD_LATEST_SAVE": "false"})
                    expected = name if name.startswith("/") else str(Path(f.env["SAVES"]) / name)
                    self.assertTrue(Path(expected).exists())
                    args = self.args()[-1]
                    self.assertEqual(args[args.index("--start-server") + 1], expected)

    def test_missing_named_save_does_not_load_another_world(self):
        f = self.fixture
        saves = Path(f.env["SAVES"])
        saves.mkdir()
        (saves / "different.zip").touch()
        for script in fixtures.ENTRYPOINTS[:2]:
            result = f.run_script(script, {"SAVE_NAME": "missing", "LOAD_LATEST_SAVE": "false"}, success=False)
            self.assertIn("Selected save does not exist", result.stderr)

    def test_bind_port_does_not_conflict_with_port_flag(self):
        f = self.fixture
        cases = {"": True, "127.0.0.1": True, "127.0.0.1:34201": False,
                 "localhost:34201": False, "::1": True, "2001:db8::1234": True,
                 "[::1]": True, "[::1]:34201": False}
        for script in fixtures.ENTRYPOINTS[:2]:
            for bind, include_port in cases.items():
                with self.subTest(script=script, bind=bind):
                    f.run_script(script, {"BIND": bind, "PORT": "34198"})
                    args = self.args()[-1]
                    self.assertEqual("--port" in args, include_port)
                    if include_port:
                        self.assertEqual(args[args.index("--port") + 1], "34198")
                    if bind:
                        self.assertEqual(args[args.index("--bind") + 1], bind)

    def test_all_entrypoints_apply_dlc_to_selected_mod_directory(self):
        f = self.fixture
        f.write_command(f.scripts / "docker-dlc.sh", (fixtures.FILES / "docker-dlc.sh").read_text())
        mods = f.work / "custom mods"
        mods.mkdir()
        for script in (*fixtures.ENTRYPOINTS, "scenario2map.sh"):
            with self.subTest(script=script):
                f.run_script(script, {"MODS": str(mods), "DLC_SPACE_AGE": "false"})
                enabled = {item["name"]: item["enabled"] for item in json.loads((mods / "mod-list.json").read_text())["mods"]}
                for name in ("space-age", "quality", "elevated-rails", "recycler"):
                    self.assertFalse(enabled[name])
                args = self.args()[-1]
                self.assertEqual(args[args.index("--mod-directory") + 1], str(mods))
                f.run_script(script, {"MODS": str(mods), "DLC_SPACE_AGE": "elevated-rails"})
                enabled = {item["name"]: item["enabled"] for item in json.loads((mods / "mod-list.json").read_text())["mods"]}
                self.assertTrue(enabled["elevated-rails"])
                self.assertFalse(enabled["space-age"])
                self.assertFalse(enabled["recycler"])

    def test_privilege_drop_executes_without_runuser_supervisor(self):
        f = self.fixture
        f.write_command(f.scripts / "id", "#!/bin/sh\necho 0\n")
        for command in ("usermod", "groupmod", "chown"):
            f.write_command(f.scripts / command, "#!/bin/sh\nexit 0\n")
        f.write_command(f.scripts / "runuser", "#!/bin/sh\nexit 99\n")
        f.write_command(f.scripts / "setpriv", '''#!/usr/bin/env python3
import os, sys
assert sys.argv[1:5] == ["--reuid=factorio", "--regid=factorio", "--init-groups", "--"]
os.execv(sys.argv[5], sys.argv[5:])
''')
        f.run_script("docker-entrypoint.sh")
        self.assertIn("--start-server-load-latest", self.args()[-1])


if __name__ == "__main__":
    unittest.main()
