#!/bin/bash
SEMVER_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"

version=$(curl 'https://www.factorio.com/updater/get-available-versions?apiVersion=2' | jq '.[] | .[] | select(.stable) | .stable' -r)
sha256=$(curl "https://www.factorio.com/get-download/${version}/headless/linux64" -L | sha256sum | awk '{print $1}')
currentversion=$(jq 'with_entries(select(contains({value:{tags:["stable"]}}))) | keys | .[0]' buildinfo.json -r)
echo "version:$version currentversion:$currentversion"
if [[ "$currentversion" == "$version" ]]; then
    exit
fi

function get-semver(){
    local ver=$1
    local type=$2
    if [[ "$ver" =~ $SEMVER_REGEX ]]; then
        local major=${BASH_REMATCH[1]}
        local minor=${BASH_REMATCH[2]}
        local patch=${BASH_REMATCH[3]}
    fi
    case $type in
        major)
            echo $major
            ;;
        minor)
            echo $minor
            ;;
        patch)
            echo $patch
            ;;
    esac
}

versionMajor=$(get-semver $version major)
versionMinor=$(get-semver $version minor)
currentversionMajor=$(get-semver $currentversion major)
currentversionMinor=$(get-semver $currentversion minor)

versionShort=$versionMajor.$versionMinor
currentversionShort=$currentversionMajor.$currentversionMinor
echo "versionShort=$versionShort currentversionShort=$currentversionShort"

tmpfile=$(mktemp)
cp buildinfo.json "$tmpfile"
if [[ $versionShort == $currentversionShort ]]; then
    jq --arg currentversion $currentversion --arg version $version --arg sha256 $sha256 'with_entries(if .key == $currentversion then .key |= $version | .value.sha256 |= $sha256 | .value.tags |= . - [$currentversion] + [$version] else . end)' "$tmpfile" > buildinfo.json
else
    jq --arg currentversion $currentversion --arg version $version --arg sha256 $sha256 --arg versionShort $versionShort --arg versionMajor $versionMajor 'with_entries(if .key == $currentversion then .value.tags |= . - ["latest","stable",$versionMajor] else . end) | to_entries | . + [{ key: $version, value: { sha256: $sha256, tags: ["latest","stable",$versionMajor,$versionShort,$version]}}] | from_entries' "$tmpfile" > buildinfo.json
fi
rm -f -- "$tmpfile"

git config user.name github-actions[bot]
git config user.email 41898282+github-actions[bot]@users.noreply.github.com
git add buildinfo.json
git commit -a -m "Auto Update Factorio to version: $version"
git tag -f latest
git push
git push origin --tags -f
