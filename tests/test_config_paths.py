"""Run entrypoint/config-path regressions without Factorio or network access."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
FILES = ROOT / "docker" / "files"
PATHS = {
    "SERVER_SETTINGS_FILE": ("--server-settings", "server-settings.json"),
    "SERVER_ID_FILE": ("--server-id", "server-id.json"),
    "SERVER_ADMINLIST_FILE": ("--server-adminlist", "server-adminlist.json"),
    "SERVER_BANLIST_FILE": ("--server-banlist", "server-banlist.json"),
    "SERVER_WHITELIST_FILE": ("--server-whitelist", "server-whitelist.json"),
}
ENTRYPOINTS = ("docker-entrypoint.sh", "docker-entrypoint-rootless.sh", "scenario.sh")


class ConfigPathTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.scripts = self.work / "scripts"
        self.scripts.mkdir()
        self.opt = self.work / "opt"
        for directory in ("data", "bin/x64", "config"):
            (self.opt / directory).mkdir(parents=True)
        self.volume = self.work / "volume"
        self.volume.mkdir()
        self.config = self.volume / "config"
        self.config.mkdir()
        self.calls = self.work / "calls.jsonl"
        self.credentials = self.work / "credentials.json"
        self.env = {**os.environ, "PATH": f"{self.scripts}:{os.environ['PATH']}",
                    "CONFIG": str(self.config), "PORT": "34197", "RCON_PORT": "27015",
                    "PUID": "845", "PGID": "845", "VERSION": "2.1.24", "UPDATE_MODS_ON_START": "false",
                    "CALLS": str(self.calls), "CREDENTIALS": str(self.credentials), "DLC_SPACE_AGE": "false"}
        for name in ("SAVES", "MODS", "SCENARIOS", "SCRIPTOUTPUT"):
            self.env[name] = str(self.volume / name.lower())
        for name in (*PATHS, "USERNAME", "TOKEN", "BASH_ENV"):
            self.env.pop(name, None)
        for source in FILES.glob("*.sh"):
            # Redirect only absolute container paths. Startup logic and shared helper stay intact.
            contents = source.read_text().replace("/opt/factorio", str(self.opt))
            contents = contents.replace("FACTORIO_VOL=/factorio", f"FACTORIO_VOL={self.volume}")
            contents = contents.replace("/run/secrets", str(self.work / "secrets"))
            target = self.scripts / source.name
            target.write_text(contents)
            target.chmod(0o755)
        self.write_command(self.scripts / "id", "#!/bin/sh\nprintf '1000\\n'\n")
        self.write_command(self.scripts / "pwgen", "#!/bin/sh\nprintf 'test-password\\n'\n")
        self.write_command(self.scripts / "docker-dlc.sh", "#!/bin/sh\nexit 0\n")
        self.write_command(self.scripts / "update-mods.sh", """#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
Path(os.environ['CREDENTIALS']).write_text(json.dumps(sys.argv[1:]))
""")
        self.write_command(self.opt / "bin/x64/factorio", """#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
with open(os.environ['CALLS'], 'a') as stream:
    stream.write(json.dumps(sys.argv[1:]) + '\\n')
if '--create' in sys.argv:
    Path(sys.argv[sys.argv.index('--create') + 1]).touch()
""")
        self.example = {"name": "example", "username": "file-user", "token": "file-token"}
        (self.opt / "data/server-settings.example.json").write_text(json.dumps(self.example))
        for name in ("map-settings", "map-gen-settings"):
            (self.opt / f"data/{name}.example.json").write_text("{}")
        (self.opt / "config/config.ini").write_text("write-data=/factorio\n")

    @staticmethod
    def write_command(path, contents):
        path.write_text(contents)
        path.chmod(0o755)

    def run_script(self, script, overrides=None, success=True):
        args = ["bash", str(self.scripts / script)]
        if script.startswith("scenario"):
            args.append("freeplay")
        if self.calls.exists():
            self.calls.unlink()
        result = subprocess.run(args, cwd=self.scripts, env={**self.env, **(overrides or {})},
                                capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse(self.calls.exists(), "Invalid path must fail before starting Factorio")
        return result

    def assert_paths(self, overrides):
        args = json.loads(self.calls.read_text().splitlines()[-1])
        for variable, (flag, filename) in PATHS.items():
            expected = overrides.get(variable) or str(self.config / filename)
            self.assertEqual(args[args.index(flag) + 1], expected)

    def test_defaults_and_empty_overrides(self):
        for script in ENTRYPOINTS:
            for overrides in ({}, dict.fromkeys(PATHS, "")):
                with self.subTest(script=script, overrides=overrides):
                    self.run_script(script, overrides)
                    self.assert_paths(overrides)

    def test_individual_and_combined_overrides_with_spaces(self):
        all_paths = {variable: str(self.work / "custom dir" / filename)
                     for variable, (_, filename) in PATHS.items()}
        for script in ENTRYPOINTS:
            for overrides in [{name: value} for name, value in all_paths.items()] + [all_paths]:
                with self.subTest(script=script, overrides=overrides):
                    self.run_script(script, overrides)
                    self.assert_paths(overrides)
                    for path in overrides.values():
                        self.assertTrue(Path(path).parent.is_dir())

    def test_custom_settings_created_and_existing_file_preserved(self):
        path = self.work / "separate settings" / "settings.json"
        for script in ENTRYPOINTS:
            with self.subTest(script=script):
                if path.exists():
                    path.chmod(0o644)
                    path.unlink()
                self.run_script(script, {"SERVER_SETTINGS_FILE": str(path)})
                self.assertEqual(json.loads(path.read_text()), self.example)
                path.write_text('{"name":"keep me"}')
                path.chmod(0o444)
                self.run_script(script, {"SERVER_SETTINGS_FILE": str(path)})
                self.assertEqual(path.read_text(), '{"name":"keep me"}')

    def test_invalid_paths_fail_before_startup(self):
        directory = self.work / "directory"
        directory.mkdir()
        for script in ENTRYPOINTS:
            for variable in PATHS:
                for path in ("relative.json", str(directory), str(self.work / "trailing") + "/"):
                    with self.subTest(script=script, variable=variable, path=path):
                        result = self.run_script(script, {variable: path}, success=False)
                        self.assertIn("Invalid server config path", result.stderr)

    def test_blocked_parent_fails_before_startup(self):
        blocker = self.work / "not-a-directory"
        blocker.touch()
        for script in ENTRYPOINTS:
            with self.subTest(script=script):
                self.run_script(script, {"SERVER_SETTINGS_FILE": str(blocker / "settings.json")}, success=False)

    def test_mod_updater_uses_custom_settings_and_explicit_credentials_win(self):
        settings = self.work / "credentials settings.json"
        settings.write_text(json.dumps(self.example))
        for script in ("docker-entrypoint.sh", "docker-entrypoint-rootless.sh", "docker-update-mods.sh"):
            with self.subTest(script=script):
                overrides = {"SERVER_SETTINGS_FILE": str(settings), "UPDATE_MODS_ON_START": "true"}
                self.run_script(script, overrides)
                self.assertEqual(json.loads(self.credentials.read_text())[2:4], ["file-user", "file-token"])
                self.run_script(script, {**overrides, "USERNAME": "explicit-user", "TOKEN": "explicit-token"})
                self.assertEqual(json.loads(self.credentials.read_text())[2:4], ["explicit-user", "explicit-token"])

    def test_scenario_conversion_uses_custom_settings(self):
        settings = self.work / "conversion" / "settings.json"
        self.run_script("scenario2map.sh", {"SERVER_SETTINGS_FILE": str(settings)})
        self.assertEqual(json.loads(settings.read_text()), self.example)
        self.assertEqual(json.loads(self.calls.read_text()), ["--scenario2map", "freeplay"])


if __name__ == "__main__":
    unittest.main()
