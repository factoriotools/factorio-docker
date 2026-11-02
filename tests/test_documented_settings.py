"""Execute the documented JSON provisioning command without Docker or network."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
VARIABLES = ("INSTANCE_NAME", "INSTANCE_DESC", "USERNAME", "TOKEN", "GAME_PASSWORD")


def example_yaml():
    text = (ROOT / "README.md").read_text()
    return text.split("<!-- start settings provisioning example -->\n```yaml\n", 1)[1].split("```", 1)[0]


def example_script():
    block = example_yaml().split("      - |\n", 1)[1]
    return "\n".join(line[8:] for line in block.splitlines())


class DocumentedSettingsTests(unittest.TestCase):
    def render(self, overrides, template=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "config"
            config.mkdir()
            output = config / "server-settings.json"
            output.write_text('{"keep":"existing settings"}')
            source = root / "template.json"
            source.write_text(template if template is not None else json.dumps({
                "name": "original name", "description": "original description",
                "username": "original user", "token": "original token",
                "game_password": "original password", "visibility": {"public": False}}))
            script = example_script().replace("/factorio/config", str(config))
            script = script.replace("/server-settings.template.json", str(source))
            script = script.replace("exec /docker-entrypoint.sh", "exec /bin/true")
            env = {key: value for key, value in os.environ.items() if key not in VARIABLES}
            result = subprocess.run(["sh", "-ec", script], env={**env, **overrides},
                                    capture_output=True, text=True)
            return result, json.loads(output.read_text())

    def test_json_special_characters_are_encoded(self):
        value = 'quotes " backslash \\ newline\nUnicode ü $(must-not-execute)'
        result, settings = self.render(dict.fromkeys(VARIABLES, value))
        self.assertEqual(result.returncode, 0, result.stderr)
        for key in ("name", "description", "username", "token", "game_password"):
            self.assertEqual(settings[key], value)
        self.assertEqual(settings["visibility"], {"public": False})

    def test_unset_values_preserve_template_and_empty_values_override(self):
        result, settings = self.render({"INSTANCE_NAME": "", "INSTANCE_DESC": "new"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(settings["name"], "")
        self.assertEqual(settings["description"], "new")
        self.assertEqual(settings["username"], "original user")
        self.assertEqual(settings["token"], "original token")

    def test_invalid_template_preserves_existing_settings(self):
        result, settings = self.render({}, template="not JSON")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(settings, {"keep": "existing settings"})

    def test_normal_compose_uses_published_image_without_build_args(self):
        text = (ROOT / "docker-compose.yml").read_text()
        self.assertIn("image: factoriotools/factorio:stable", text)
        self.assertNotIn("    build:", text)
        self.assertNotIn("SHA256=", text)
        self.assertIn("stop_grace_period: 2m", text)
        self.assertIn("UPDATE_MODS_ON_START=false", text)


if __name__ == "__main__":
    unittest.main()
