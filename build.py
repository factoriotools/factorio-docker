#!/usr/bin/env python3

import os
import json
import subprocess
import shutil
import tempfile

from jinja2 import Environment, FileSystemLoader

jinja_env = Environment(
    loader=FileSystemLoader('templates')
)


def build_dockerfile(sha1, version, tags):
    build_dir = tempfile.mktemp()
    shutil.copytree("docker", build_dir)
    template = jinja_env.get_template("Dockerfile.jinja2")
    dockerfile_content = template.render(sha1=sha1, version=version)
    with open(os.path.join(build_dir, "Dockerfile"), "w") as dockerfile:
        dockerfile.write(dockerfile_content)
    build_command = ["docker", "build", "."]
    for tag in tags:
        build_command.extend(["-t", f"factoriotools/factorio:{tag}"])
    subprocess.run(build_command, cwd=build_dir)


def main():
    with open(os.path.join(os.path.dirname(__file__), "buildinfo.json")) as file_handle:
        builddata = json.load(file_handle)

    for version, buildinfo in builddata.items():
        sha1 = buildinfo["sha1"]
        tags = buildinfo["tags"]
        build_dockerfile(sha1, version, tags)
        for tag in tags:
            subprocess.run(["docker", "push", f"factoriotools/factorio:{tag}"])


if __name__ == '__main__':
    main()
