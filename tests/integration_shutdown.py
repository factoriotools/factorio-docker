"""Docker SIGTERM regression: python3 tests/integration_shutdown.py IMAGE.

Uses a deliberately slow fake server to reproduce runuser's two-second kill,
without requiring a large user save. Creates/removes only its own container
and volume. The supplied image must contain the real regular entrypoint.
"""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import uuid


def docker(*args, **kwargs):
    return subprocess.run(["docker", *args], check=True, capture_output=True, text=True, **kwargs)


def main(image):
    name = "factorio-shutdown-" + uuid.uuid4().hex[:12]
    volume = name + "-data"
    docker("volume", "create", volume)
    try:
        with tempfile.TemporaryDirectory() as directory:
            server = Path(directory) / "factorio"
            server.write_text('''#!/bin/bash
if [[ "$1" == --create ]]; then
  touch "$2"
  exit 0
fi
trap 'sleep 5; echo complete > /factorio/shutdown-complete; exit 0' TERM
id -u > /factorio/server-uid
echo ready > /factorio/server-ready
while true; do sleep 0.1; done
''')
            server.chmod(0o755)
            # The container user must be able to traverse the fixture directory.
            Path(directory).chmod(0o755)
            try:
                docker("run", "-d", "--name", name, "--network", "none",
                       "--mount", f"type=volume,src={volume},dst=/factorio",
                       "--mount", f"type=bind,src={server},dst=/opt/factorio/bin/x64/factorio,readonly",
                       "-e", "DLC_SPACE_AGE=false", image)
                for _ in range(100):
                    ready = subprocess.run(["docker", "exec", name, "test", "-f", "/factorio/server-ready"],
                                           capture_output=True)
                    if ready.returncode == 0:
                        break
                    time.sleep(0.1)
                else:
                    raise AssertionError("Server did not start: " + docker("logs", name).stdout)
                start = time.monotonic()
                docker("stop", "--timeout", "15", name, timeout=25)
                elapsed = time.monotonic() - start
                state = json.loads(docker("inspect", name).stdout)[0]["State"]
                if state["ExitCode"] != 0:
                    raise AssertionError(f"Shutdown interrupted after {elapsed:.2f}s: {state['ExitCode']}\n"
                                         + docker("logs", name).stderr)
                docker("cp", f"{name}:/factorio/shutdown-complete", str(Path(directory) / "complete"))
                docker("cp", f"{name}:/factorio/server-uid", str(Path(directory) / "uid"))
                assert (Path(directory) / "complete").read_text().strip() == "complete"
                assert (Path(directory) / "uid").read_text().strip() == "845"
                assert elapsed >= 5, elapsed
                print(f"PASS: UID 845 server completed a five-second save after SIGTERM ({elapsed:.2f}s)")
            finally:
                subprocess.run(["docker", "rm", "-f", name], capture_output=True)
    finally:
        docker("volume", "rm", volume)


if __name__ == "__main__":
    main(sys.argv[1])
