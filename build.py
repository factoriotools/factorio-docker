#!/usr/bin/env python3

import os
import json
import subprocess
import shutil
import sys
import tempfile


PLATFORMS = [
    "linux/arm64",
    "linux/amd64",
]


def create_builder(build_dir, builder_name, platform):
    check_exists_command = ["docker", "buildx", "inspect", builder_name]
    if subprocess.run(check_exists_command, stderr=subprocess.DEVNULL).returncode != 0:
        create_command = ["docker", "buildx", "create", "--platform", platform, "--name", builder_name]
        try:
            subprocess.run(create_command, cwd=build_dir, check=True)
        except subprocess.CalledProcessError:
            print("Creating builder failed")
            exit(1)


def build_and_push_multiarch(build_dir, build_args, push):
    builder_name = "factoriotools-multiarch"
    platform=",".join(PLATFORMS)
    create_builder(build_dir, builder_name, platform)
    build_command = ["docker", "buildx", "build", "--platform", platform, "--builder", builder_name] + build_args
    if push:
        build_command.append("--push")
    try:
        subprocess.run(build_command, cwd=build_dir, check=True)
    except subprocess.CalledProcessError:
        print("Build and push of image failed")
        exit(1)


def build_singlearch(build_dir, build_args):
    build_command = ["docker", "build"] + build_args
    try:
        subprocess.run(build_command, cwd=build_dir, check=True)
    except subprocess.CalledProcessError:
        print("Build of image failed")
        exit(1)


def push_singlearch(tags):
    for tag in tags:
        try:
            subprocess.run(["docker", "push", f"factoriotools/factorio:{tag}"],
                            check=True)
        except subprocess.CalledProcessError:
            print("Docker push failed")
            exit(1)


def build_and_push(sha256, version, tags, push, multiarch):
    build_dir = tempfile.mktemp()
    shutil.copytree("docker", build_dir)
    build_args = ["--build-arg", f"VERSION={version}", "--build-arg", f"SHA256={sha256}", "."]
    for tag in tags:
        build_args.extend(["-t", f"factoriotools/factorio:{tag}"])
    if multiarch:
        build_and_push_multiarch(build_dir, build_args, push)
    else:
        build_singlearch(build_dir, build_args)
        if push:
            push_singlearch(tags)


def login():
    try:
        username = os.environ["DOCKER_USERNAME"]
        password = os.environ["DOCKER_PASSWORD"]
        subprocess.run(["docker", "login", "-u", username, "-p", password], check=True)
    except KeyError:
        print("Username and password need to be given")
        exit(1)
    except subprocess.CalledProcessError:
        print("Docker login failed")
        exit(1)


def main(push_tags=False, multiarch=False):
    with open(os.path.join(os.path.dirname(__file__), "buildinfo.json")) as file_handle:
        builddata = json.load(file_handle)

    if push_tags:
        login()

    for version, buildinfo in sorted(builddata.items(), key=lambda item: item[0], reverse=True):
        sha256 = buildinfo["sha256"]
        tags = buildinfo["tags"]
        build_and_push(sha256, version, tags, push_tags, multiarch)


if __name__ == '__main__':
    push_tags = False
    multiarch = False
    for arg in sys.argv[1:]:
        if arg == "--push-tags":
            push_tags = True
        elif arg == "--multiarch":
            multiarch = True
    main(push_tags, multiarch)
