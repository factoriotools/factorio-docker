#!/usr/bin/env python3

from datetime import datetime
from hashlib import sha1
from os import rename, scandir, unlink
from os.path import exists
from sys import argv
from urllib.parse import quote as url_quote, urlencode
from requests import get
from json import loads as json_loads
from dateutil import parser as dateutil_parser


class FactorioVersion():
    version: list[int]
    version_str: str

    def __init__(self, version: str) -> None:
        self.version = [int(v, 10) for v in version.split(".")]
        self.version_str = version

    def _version_at(self, i: int) -> int:
        if i >= len(self.version):
            return 0
        return self.version[i]

    def _compare(self, other) -> int:
        for i in range(max(len(self.version), len(other.version))):
            selfVersion = self._version_at(i)
            otherVersion = other._version_at(i)
            if selfVersion == otherVersion:
                continue
            if selfVersion < otherVersion:
                return -1
            else:
                return 1
        return 0

    def __eq__(self, other) -> bool:
        return self._compare(other) == 0

    def __lt__(self, other) -> bool:
        return self._compare(other) < 0

    def __le__(self, other) -> bool:
        return self._compare(other) <= 0


INVERTED_CONSTRAINTS = {"<": ">=", "<=": ">",
                        "=": "!=", "!=": "=", ">=": "<", ">": "<="}


class FactorioVersionConstraint():
    constraint: str
    version: FactorioVersion

    def __init__(self, constraint: str, version: FactorioVersion, invert: bool) -> None:
        if constraint not in INVERTED_CONSTRAINTS:
            raise ValueError(f"Unknown constraint: {constraint}")

        if invert:
            constraint = INVERTED_CONSTRAINTS[constraint]

        self.constraint = constraint
        self.version = version

    def matches(self, version: FactorioVersion) -> bool:
        if self.constraint == "<":
            return version < self.version
        elif self.constraint == "<=":
            return version <= self.version
        elif self.constraint == "=":
            return version == self.version
        elif self.constraint == "!=":
            return version != self.version
        elif self.constraint == ">=":
            return version >= self.version
        elif self.constraint == ">":
            return version > self.version

        raise ValueError(f"Unknown constraint: {self.constraint}")


class FactorioModRelease():
    url: str
    file_name: str
    sha1: str
    factorio_version_constraints: list[FactorioVersionConstraint]
    version: str
    released_at: datetime

    def __init__(self, mod_name: str, raw) -> None:
        self.url = raw["download_url"]
        self.file_name = raw["file_name"]

        self.factorio_version_constraints = []
        for dep in raw["info_json"]["dependencies"]:
            dep_split = dep.split(" ")
            invert = False
            if dep_split[0] == "!":
                invert = True
                dep_split = dep_split[1:]
            elif dep_split[0] == "?" or dep_split[0] == "(?)" or dep_split[0] == "~":
                dep_split = dep_split[1:]

            if dep_split[0] != "base":
                continue

            if len(dep_split) < 3:
                continue

            self.factorio_version_constraints.append(FactorioVersionConstraint(
                dep_split[1], FactorioVersion(dep_split[2]), invert))

        self.version = raw["version"]
        self.sha1 = raw["sha1"]

        self.released_at = dateutil_parser.isoparse(raw["released_at"])

        if self.file_name != f"{mod_name}_{self.version}.zip":
            raise ValueError("Invalid mod naming pattern")

    def is_compatible_with(self, factorio_version: FactorioVersion) -> bool:
        for constraint in self.factorio_version_constraints:
            if not constraint.matches(factorio_version):
                return False
        return True

    def __eq__(self, other) -> bool:
        return self.released_at == other.released_at

    def __lt__(self, other) -> bool:
        return self.released_at < other.released_at

    def __le__(self, other) -> bool:
        return self.released_at <= other.released_at


class FactorioMod():
    name: str
    releases: list[FactorioModRelease]

    def __init__(self, name: str) -> None:
        self.name = name
        self.info = None
        self.releases = None

    def fetch_info(self) -> None:
        url = f"{MOD_BASE_URL}/api/mods/{url_quote(self.name)}/full"

        with get(url) as info_res:
            info_res.raise_for_status()
            self.info = json_loads(info_res.text)

        self.releases = [FactorioModRelease(self.name,
                                            release) for release in self.info["releases"]]
        self.releases.sort(reverse=True)

    def get_latest_version_for(self, factorio_version: FactorioVersion) -> FactorioModRelease:
        for release in self.releases:
            if release.is_compatible_with(factorio_version):
                return release
        return None

    def is_release_installed(self, release: FactorioModRelease) -> bool:
        return exists(f"{MOD_DIR}/{release.file_name}")

    def uninstall_all_except(self, release: FactorioModRelease) -> None:
        prefix = f"{self.name}_"
        prefix_len = len(prefix)

        for dirent in scandir(MOD_DIR):
            if not dirent.is_file():
                continue
            name = dirent.name
            if name[0] == "." or name[-4:] != ".zip":
                continue
            if name[:prefix_len] != prefix:
                continue
            if name == release.file_name:
                continue
            print(f"Uninstall mod release: {dirent.name}")
            unlink(dirent.path)

    def install_release(self, release: FactorioModRelease) -> None:
        params = {
            "token": TOKEN,
            "username": USERNAME,
        }
        url = f"{MOD_BASE_URL}{release.url}?{urlencode(params)}"
        local_filename_target = f"{MOD_DIR}/{release.file_name}"
        local_filename_tmp = f"{local_filename_target}.tmp"

        expected_hash = release.sha1
        current_hash = sha1()

        with get(url, stream=True) as r:
            r.raise_for_status()
            with open(local_filename_tmp, "wb") as fh:
                for chunk in r.iter_content(chunk_size=4096):
                    fh.write(chunk)
                    current_hash.update(chunk)

        actual_hash = current_hash.hexdigest()

        if actual_hash != expected_hash:
            raise ValueError("Hash mismatch")

        rename(local_filename_tmp, local_filename_target)


FACTORIO_VERSION = FactorioVersion(argv[1])
MOD_DIR = argv[2]
USERNAME = argv[3]
TOKEN = argv[4]

MOD_BASE_URL = "https://mods.factorio.com"

def cleanup():
    for dirent in scandir(MOD_DIR):
        if not dirent.is_file():
            continue
        name = dirent.name
        if name[0] == "." or name[-4:] != ".tmp":
            continue
        print(f"Cleanup temp file: {dirent.name}")
        unlink(dirent.path)


def check_mod(mod: FactorioMod):
    print("")
    print(f"Checking {mod.name}...")
    
    mod.fetch_info()
    release = mod.get_latest_version_for(FACTORIO_VERSION)
    
    if mod.is_release_installed(release):
        print(f"    Mod {mod.name} up to date at {release.version}!")
    else:
        print(f"    Updating mod {mod.name} to {release.version}")
        mod.install_release(release)
        mod.uninstall_all_except(release)


def main():
    print("Loading mod-list.json")
    all_mods = []
    with open(f"{MOD_DIR}/mod-list.json") as f:
        mods_info = json_loads(f.read())["mods"]
        for mod in mods_info:
            name = mod["name"]
            if name == "base" or not mod["enabled"]:
                continue
            all_mods.append(FactorioMod(name))

    cleanup()

    print("Checking all mod updates...")
    for mod in all_mods:
        check_mod(mod)
    print("")
    print("Update check complete")

    cleanup()


if __name__ == "__main__":
    main()
