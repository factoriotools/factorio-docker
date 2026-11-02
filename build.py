#!/usr/bin/env python3

import os
import json
import subprocess
import shutil
import sys
import tempfile
import argparse


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


def build_and_push_multiarch(build_dir, build_args, push, builder_suffix=""):
    builder_name = f"factoriotools{builder_suffix}-multiarch"
    platform = ",".join(PLATFORMS)
    create_builder(build_dir, builder_name, platform)
    build_command = ["docker", "buildx", "build", "--platform", platform, "--builder", builder_name] + build_args
    if push:
        build_command.append("--push")
    try:
        subprocess.run(build_command, cwd=build_dir, check=True)
    except subprocess.CalledProcessError:
        print(f"Build and push of {builder_suffix or 'regular'} image failed")
        exit(1)


def build_singlearch(build_dir, build_args, image_type="regular"):
    build_command = ["docker", "build"] + build_args
    try:
        subprocess.run(build_command, cwd=build_dir, check=True)
    except subprocess.CalledProcessError:
        print(f"Build of {image_type} image failed")
        exit(1)


def push_singlearch(tags):
    for tag in tags:
        try:
            subprocess.run(["docker", "push", f"factoriotools/factorio:{tag}"],
                            check=True)
        except subprocess.CalledProcessError:
            print("Docker push failed")
            exit(1)


def build_and_push(sha256, version, tags, push, multiarch, dockerfile="Dockerfile", builder_suffix=""):
    build_dir = tempfile.mktemp()
    shutil.copytree("docker", build_dir)
    build_args = ["-f", dockerfile, "--build-arg", f"VERSION={version}", "--build-arg", f"SHA256={sha256}", "."]
    for tag in tags:
        build_args.extend(["-t", f"factoriotools/factorio:{tag}"])
    
    image_type = "rootless" if "rootless" in dockerfile.lower() else "regular"
    
    if multiarch:
        build_and_push_multiarch(build_dir, build_args, push, builder_suffix)
    else:
        build_singlearch(build_dir, build_args, image_type)
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


def generate_rootless_tags(original_tags):
    """Generate rootless-specific tags from original tags"""
    return [f"{tag}-rootless" for tag in original_tags]


def main():
    parser = argparse.ArgumentParser(description='Build Factorio Docker images')
    parser.add_argument('--push-tags', action='store_true', help='Push images to Docker Hub')
    parser.add_argument('--multiarch', action='store_true', help='Build multi-architecture images')
    parser.add_argument('--rootless', action='store_true', help='Build only rootless images')
    parser.add_argument('--both', action='store_true', help='Build both regular and rootless images')
    parser.add_argument('--only-stable-latest', action='store_true', 
                        help='Build only stable and latest versions (for rootless by default)')
    
    args = parser.parse_args()
    
    # Default behavior: build regular images unless specified otherwise
    build_regular = not args.rootless or args.both
    build_rootless = args.rootless or args.both
    
    with open(os.path.join(os.path.dirname(__file__), "buildinfo.json")) as file_handle:
        builddata = json.load(file_handle)

    if args.push_tags:
        login()

    # Filter versions if needed
    versions_to_build = []
    for version, buildinfo in sorted(builddata.items(), key=lambda item: item[0], reverse=True):
        if args.only_stable_latest or (build_rootless and not build_regular):
            # For rootless-only builds, default to stable/latest only
            if "stable" in buildinfo["tags"] or "latest" in buildinfo["tags"]:
                versions_to_build.append((version, buildinfo))
        else:
            versions_to_build.append((version, buildinfo))
    
    # Build regular images
    if build_regular:
        print("Building regular images...")
        for version, buildinfo in versions_to_build:
            sha256 = buildinfo["sha256"]
            tags = buildinfo["tags"]
            build_and_push(sha256, version, tags, args.push_tags, args.multiarch)
    
    # Build rootless images
    if build_rootless:
        print("Building rootless images...")
        # For rootless, only build stable and latest unless building both
        rootless_versions = []
        if not build_regular or args.only_stable_latest:
            for version, buildinfo in builddata.items():
                if "stable" in buildinfo["tags"] or "latest" in buildinfo["tags"]:
                    rootless_versions.append((version, buildinfo))
        else:
            rootless_versions = versions_to_build
            
        for version, buildinfo in rootless_versions:
            sha256 = buildinfo["sha256"]
            original_tags = buildinfo["tags"]
            rootless_tags = generate_rootless_tags(original_tags)
            build_and_push(sha256, version, rootless_tags, args.push_tags, args.multiarch, 
                         dockerfile="Dockerfile.rootless", builder_suffix="-rootless")


if __name__ == '__main__':
    main()