#!/bin/bash
set -e
SEMVER_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"

stable_online_version=$(curl 'https://factorio.com/api/latest-releases' | jq '.stable.headless' -r)
experimental_online_version=$(curl 'https://factorio.com/api/latest-releases' | jq '.experimental.headless' -r)

stable_sha256=$(curl "https://factorio.com/download/sha256sums/" | grep -E "(factorio_headless_x64_|factorio-headless_linux_)${stable_online_version}.tar.xz" | awk '{print $1}')
experimental_sha256=$(curl "https://factorio.com/download/sha256sums/" | grep -E "(factorio_headless_x64_|factorio-headless_linux_)${experimental_online_version}.tar.xz" | awk '{print $1}')

stable_current_version=$(jq 'with_entries(select(.value.tags | index("stable"))) | keys | .[0]' buildinfo.json -r)
latest_current_version=$(jq 'with_entries(select(.value.tags | index("latest"))) | keys | .[0]' buildinfo.json -r)

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

# Remove stable tag
cp buildinfo.json "$tmpfile"
jq --arg stable_current_version "$stable_current_version" 'with_entries(if .key == $stable_current_version then .value.tags |= . - ["stable"] else . end)' "$tmpfile" > buildinfo.json
rm -f -- "$tmpfile"

# Remove latest tag
cp buildinfo.json "$tmpfile"
jq --arg latest_current_version "$latest_current_version" 'with_entries(if .key == $latest_current_version then .value.tags |= . - ["latest"] else . end)' "$tmpfile" > buildinfo.json
rm -f -- "$tmpfile"

# Update tag by stable
cp buildinfo.json "$tmpfile"
if [[ "$stable_online_version" == "$stable_current_version" ]]; then
    jq --arg stable_current_version "$stable_current_version" --arg stable_online_version "$stable_online_version" --arg sha256 "$stable_sha256" 'with_entries(if .key == $stable_current_version then .key |= $stable_online_version | .value.sha256 |= $sha256 | .value.tags |= . - [$stable_current_version] + [$stable_online_version, "stable"] else . end)' "$tmpfile" > buildinfo.json
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

# Generate README tags with logical sorting and de-duplication
# First, collect all unique tags with their versions
declare -A tag_versions
while IFS= read -r version; do
  while IFS= read -r tag; do
    # If this tag is already seen, compare versions to keep the latest
    if [[ -n "${tag_versions[$tag]}" ]]; then
      # Compare version strings - keep the higher one
      if [[ "$version" > "${tag_versions[$tag]}" ]]; then
        tag_versions[$tag]="$version"
      fi
    else
      tag_versions[$tag]="$version"
    fi
  done < <(jq -r ".\"$version\".tags[]" buildinfo.json)
done < <(jq -r 'keys[]' buildinfo.json | sort -V -r)

# Build the tags list for README
readme_tags=""
# First add the current latest and stable tags
latest_version=$(jq -r 'to_entries | map(select(.value.tags | contains(["latest"]))) | .[0].key' buildinfo.json)
stable_version=$(jq -r 'to_entries | map(select(.value.tags | index("stable"))) | .[0].key' buildinfo.json)

if [[ -n "$latest_version" ]]; then
  latest_tags=$(jq -r ".\"$latest_version\".tags | map(select(. == \"latest\" or . == \"$latest_version\")) | join(\", \")" buildinfo.json | sed 's/"/`/g')
  readme_tags="${readme_tags}\n* \`${latest_tags}\`"
fi

if [[ -n "$stable_version" ]] && [[ "$stable_version" != "$latest_version" ]]; then
  stable_tags=$(jq -r ".\"$stable_version\".tags | sort | join(\", \")" buildinfo.json | sed 's/"/`/g')
  readme_tags="${readme_tags}\n* \`${stable_tags}\`"
fi

# Add major.minor tags (e.g., 2.0, 1.1) - only the latest version for each
declare -A major_minor_seen
while IFS= read -r version; do
  if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    major_minor="$major.$minor"
    
    # Skip if this is the latest or stable version (already added above)
    if [[ "$version" == "$latest_version" ]] || [[ "$version" == "$stable_version" ]]; then
      continue
    fi
    
    # Only add if we haven't seen this major.minor yet
    if [[ -z "${major_minor_seen[$major_minor]}" ]]; then
      major_minor_seen[$major_minor]=1
      tags=$(jq -r ".\"$version\".tags | join(\", \")" buildinfo.json | sed 's/"/`/g')
      if [[ -n "$tags" ]]; then
        readme_tags="${readme_tags}\n* \`${tags}\`"
      fi
    fi
  fi
done < <(jq -r 'keys[]' buildinfo.json | sort -V -r)

readme_tags="${readme_tags}\n"

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
