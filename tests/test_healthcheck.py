"""Read-only RCON health probe tests, including false-positive and timeout cases."""

import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROBE = ROOT / "docker/files/docker-healthcheck.sh"


class HealthcheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        (self.work / "rconpw").write_text("fixture-password\n")
        rcon = self.work / "rcon"
        rcon.write_text('''#!/bin/sh
[ "$*" = '/players count' ] || exit 99
case "$MODE" in
  healthy) printf 'Players (12):\\n\\n';;
  empty) exit 0;;
  denied) printf 'Authentication failed\\n';;
  disconnected) exit 1;;
  hang) exec sleep 30;;
esac
''')
        rcon.chmod(0o755)
        self.env = {**os.environ, "CONFIG": str(self.work), "PATH": f"{self.work}:{os.environ['PATH']}"}

    def run_probe(self, mode):
        return subprocess.run(["bash", str(PROBE)], env={**self.env, "MODE": mode},
                              capture_output=True, text=True, timeout=10)

    def test_valid_response_is_healthy_and_quiet(self):
        result = self.run_probe("healthy")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_empty_denied_or_disconnected_are_unhealthy(self):
        for mode in ("empty", "denied", "disconnected"):
            with self.subTest(mode=mode):
                self.assertNotEqual(self.run_probe(mode).returncode, 0)

    def test_missing_or_empty_password_is_unhealthy(self):
        (self.work / "rconpw").unlink()
        self.assertNotEqual(self.run_probe("healthy").returncode, 0)
        (self.work / "rconpw").touch()
        self.assertNotEqual(self.run_probe("healthy").returncode, 0)

    def test_unresponsive_server_is_bounded(self):
        start = time.monotonic()
        self.assertNotEqual(self.run_probe("hang").returncode, 0)
        self.assertLess(time.monotonic() - start, 9)

    def test_both_image_variants_install_the_probe(self):
        for name in ("Dockerfile", "Dockerfile.rootless"):
            text = (ROOT / "docker" / name).read_text()
            self.assertIn('CMD ["/docker-healthcheck.sh"]', text)
            self.assertIn("--start-period=5m", text)
        self.assertTrue(os.access(PROBE, os.X_OK))


if __name__ == "__main__":
    unittest.main()
