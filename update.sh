#!/bin/bash
set -e
SEMVER_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"

stable_online_version=$(curl 'https://factorio.com/api/latest-releases' | jq '.stable.headless' -r)
experimental_online_version=$(curl 'https://factorio.com/api/latest-releases' | jq '.experimental.headless' -r)
stable_sha256=$(curl "https://factorio.com/download/sha256sums/" | grep "factorio_headless_x64_${stable_online_version}.tar.xz" | awk '{print $1}')
experimental_sha256=$(curl "https://factorio.com/download/sha256sums/" | grep "factorio_headless_x64_${experimental_online_version}.tar.xz" | awk '{print $1}')
stable_current_version=$(jq 'with_entries(select(contains({value:{tags:["stable"]}}))) | keys | .[0]' buildinfo.json -r)
latest_current_version=$(jq 'with_entries(select(contains({value:{tags:["latest"]}}))) | keys | .[0]' buildinfo.json -r)
echo "stable_online_version=${stable_online_version} experimental_online_version=${experimental_online_version}"
echo "stable_current_version=${stable_current_version} latest_current_version=${latest_current_version}"
if [[ -z "${stable_online_version}" ]] || [[ -z "${experimental_online_version}" ]]; then
    exit
fi
if [[ "${stable_current_version}" == "${stable_online_version}" ]] && [[ "${latest_current_version}" == "${experimental_online_version}" ]]; then
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
            echo "$major"
            ;;
        minor)
            echo "$minor"
            ;;
        patch)
            echo "$patch"
            ;;
    esac
}

stableOnlineVersionMajor=$(get-semver "${stable_online_version}" major)
stableOnlineVersionMinor=$(get-semver "${stable_online_version}" minor)
experimentalOnlineVersionMajor=$(get-semver "${experimental_online_version}" major)
experimentalOnlineVersionMinor=$(get-semver "${experimental_online_version}" minor)
stableCurrentVersionMajor=$(get-semver "${stable_current_version}" major)
stableCurrentVersionMinor=$(get-semver "${stable_current_version}" minor)
latestCurrentVersionMajor=$(get-semver "${latest_current_version}" major)
latestCurrentVersionMinor=$(get-semver "${latest_current_version}" minor)

stableOnlineVersionShort=$stableOnlineVersionMajor.$stableOnlineVersionMinor
experimentalOnlineVersionShort=$experimentalOnlineVersionMajor.$experimentalOnlineVersionMinor
stableCurrentVersionShort=$stableCurrentVersionMajor.$stableCurrentVersionMinor
latestCurrentVersionShort=$latestCurrentVersionMajor.$latestCurrentVersionMinor

echo "stableOnlineVersionShort=${stableOnlineVersionShort} experimentalOnlineVersionShort=${experimentalOnlineVersionShort}"
echo "stableCurrentVersionShort=${stableCurrentVersionShort} latestCurrentVersionShort=${latestCurrentVersionShort}"

tmpfile=$(mktemp)

# Remove latest tag
cp buildinfo.json "$tmpfile"
jq --arg latest_current_version "$latest_current_version" 'with_entries(if .key == $latest_current_version then .value.tags |= . - ["latest"] else . end)' "$tmpfile" > buildinfo.json
rm -f -- "$tmpfile"

# Update tag by stable
cp buildinfo.json "$tmpfile"
if [[ $stableOnlineVersionShort == "$stableCurrentVersionShort" ]]; then
    jq --arg stable_current_version "$stable_current_version" --arg stable_online_version "$stable_online_version" --arg sha256 "$stable_sha256" 'with_entries(if .key == $stable_current_version then .key |= $stable_online_version | .value.sha256 |= $sha256 | .value.tags |= . - [$stable_current_version] + [$stable_online_version] else . end)' "$tmpfile" > buildinfo.json
else
    jq --arg stable_current_version "$stable_current_version" --arg stable_online_version "$stable_online_version" --arg sha256 "$stable_sha256" --arg stableOnlineVersionShort "$stableOnlineVersionShort" --arg stableOnlineVersionMajor "$stableOnlineVersionMajor" 'with_entries(if .key == $stable_current_version then .value.tags |= . - ["latest","stable",$stableOnlineVersionMajor] else . end) | to_entries | . + [{ key: $stable_online_version, value: { sha256: $sha256, tags: ["latest","stable",("stable-" + $stable_online_version),$stableOnlineVersionMajor,$stableOnlineVersionShort,$stable_online_version]}}] | from_entries' "$tmpfile" > buildinfo.json
fi
rm -f -- "$tmpfile"

# Update tag by latest
cp buildinfo.json "$tmpfile"
if [[ $experimental_online_version != "$stable_online_version" ]]; then
    if [[ $stableOnlineVersionShort == "$experimentalOnlineVersionShort" ]]; then
        jq --arg experimental_online_version "$experimental_online_version" --arg stable_online_version "$stable_online_version" --arg sha256 "$experimental_sha256" 'with_entries(if .key == $stable_online_version then .value.tags |= . - ["latest"] else . end) | to_entries | . + [{ key: $experimental_online_version, value: { sha256: $sha256, tags: ["latest", $experimental_online_version]}}] | from_entries' "$tmpfile" > buildinfo.json
    else
        jq --arg experimental_online_version "$experimental_online_version" --arg stable_online_version "$stable_online_version" --arg sha256 "$experimental_sha256" --arg experimentalOnlineVersionShort   "$experimentalOnlineVersionShort" --arg experimentalOnlineVersionMajor "$experimentalOnlineVersionMajor" 'with_entries(if .key == $stable_online_version then .value.tags |= . - ["latest"] else . end) | to_entries | . + [{ key: $experimental_online_version, value: { sha256: $sha256, tags: ["latest",$experimentalOnlineVersionMajor,$experimentalOnlineVersionShort,$experimental_online_version]}}] | from_entries' "$tmpfile" > buildinfo.json
    fi
fi
rm -f -- "$tmpfile"

readme_tags=$(jq --sort-keys 'keys[]' buildinfo.json | tac | (while read -r line
do
  tags="$tags\n* "$(jq --sort-keys ".$line.tags | sort | .[]" buildinfo.json | sed 's/"/`/g' | sed ':a; /$/N; s/\n/, /; ta')
done && printf "%s\n\n" "$tags"))

perl -i -0777 -pe "s/<!-- start autogeneration tags -->.+<!-- end autogeneration tags -->/<!-- start autogeneration tags -->$readme_tags<!-- end autogeneration tags -->/s" README.md

# Replace VERSION and SHA256 args in docker-compose.yaml with latest stable values.
docker_compose_path="docker/docker-compose.yml"
sov="VERSION=${stable_online_version}" yq -i '.services.factorio.build.args[0] = env(sov)' "$docker_compose_path"
sha="SHA256=${stable_sha256}" yq -i '.services.factorio.build.args[1] = env(sha)' "$docker_compose_path"

git config user.name github-actions[bot]
git config user.email 41898282+github-actions[bot]@users.noreply.github.com

git add buildinfo.json
git add README.md
git add docker/docker-compose.yml
git commit -a -m "Auto Update Factorio to stable version: ${stable_online_version} experimental version: ${experimental_online_version}"

git tag -f latest
git push
git push origin --tags -f
