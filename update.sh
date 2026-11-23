#!/bin/bash
set -e
SEMVER_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"

latest_releases=$(curl 'https://factorio.com/api/latest-releases')
stable_online_version=$(jq -r '.stable.headless' <<< "$latest_releases")
experimental_online_version=$(jq -r '.experimental.headless' <<< "$latest_releases")

sha256sums=$(curl "https://factorio.com/download/sha256sums/")
stable_sha256=$(grep -E "(factorio_headless_x64_|factorio-headless_linux_)${stable_online_version}.tar.xz" <<< "$sha256sums" | awk '{print $1}')
experimental_sha256=$(grep -E "(factorio_headless_x64_|factorio-headless_linux_)${experimental_online_version}.tar.xz" <<< "$sha256sums" | awk '{print $1}')
# Native ARM64 headless builds exist from 2.1 on; older versions have no arm64 archive and the value stays empty.
stable_sha256_arm64=$(grep -E "factorio-headless_linux-arm64_${stable_online_version}.tar.xz" <<< "$sha256sums" | awk '{print $1}')
experimental_sha256_arm64=$(grep -E "factorio-headless_linux-arm64_${experimental_online_version}.tar.xz" <<< "$sha256sums" | awk '{print $1}')

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

# Create new buildinfo.json with only current versions
tmpfile=$(mktemp)

# Start with empty JSON object
echo '{}' > "$tmpfile"

# Add stable version
if [[ "$stable_online_version" == "$experimental_online_version" ]]; then
    # Stable and experimental are the same version
    jq --arg stable_online_version "$stable_online_version" --arg sha256 "$stable_sha256" --arg sha256_arm64 "$stable_sha256_arm64" --arg stableOnlineVersionShort "$stableOnlineVersionShort" --arg stableOnlineVersionMajor "$stableOnlineVersionMajor" \
        '. + {($stable_online_version): ({sha256: $sha256} + (if $sha256_arm64 != "" then {sha256_arm64: $sha256_arm64} else {} end) + {tags: ["latest", "stable", ("stable-" + $stable_online_version), $stableOnlineVersionMajor, $stableOnlineVersionShort, $stable_online_version]})}' "$tmpfile" > buildinfo.json
else
    # Different stable and experimental versions
    # First add stable
    jq --arg stable_online_version "$stable_online_version" --arg sha256 "$stable_sha256" --arg sha256_arm64 "$stable_sha256_arm64" --arg stableOnlineVersionShort "$stableOnlineVersionShort" --arg stableOnlineVersionMajor "$stableOnlineVersionMajor" \
        '. + {($stable_online_version): ({sha256: $sha256} + (if $sha256_arm64 != "" then {sha256_arm64: $sha256_arm64} else {} end) + {tags: ["stable", ("stable-" + $stable_online_version), $stableOnlineVersionMajor, $stableOnlineVersionShort, $stable_online_version]})}' "$tmpfile" > buildinfo.json.tmp
    mv buildinfo.json.tmp "$tmpfile"
    
    # Then add experimental
    if [[ $stableOnlineVersionShort == "$experimentalOnlineVersionShort" ]]; then
        jq --arg experimental_online_version "$experimental_online_version" --arg sha256 "$experimental_sha256" --arg sha256_arm64 "$experimental_sha256_arm64" \
            '. + {($experimental_online_version): ({sha256: $sha256} + (if $sha256_arm64 != "" then {sha256_arm64: $sha256_arm64} else {} end) + {tags: ["latest", $experimental_online_version]})}' "$tmpfile" > buildinfo.json
    else
        jq --arg experimental_online_version "$experimental_online_version" --arg sha256 "$experimental_sha256" --arg sha256_arm64 "$experimental_sha256_arm64" --arg experimentalOnlineVersionShort "$experimentalOnlineVersionShort" --arg experimentalOnlineVersionMajor "$experimentalOnlineVersionMajor" \
            '. + {($experimental_online_version): ({sha256: $sha256} + (if $sha256_arm64 != "" then {sha256_arm64: $sha256_arm64} else {} end) + {tags: ["latest", $experimentalOnlineVersionMajor, $experimentalOnlineVersionShort, $experimental_online_version]})}' "$tmpfile" > buildinfo.json
    fi
fi

rm -f -- "$tmpfile"

# Generate README tags for the current latest and stable releases.
readme_tags=""
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

readme_tags="${readme_tags}\n"

perl -i -0777 -pe "s/<!-- start autogeneration tags -->.+<!-- end autogeneration tags -->/<!-- start autogeneration tags -->$readme_tags<!-- end autogeneration tags -->/s" README.md

# Replace VERSION and SHA256 args in docker-compose.yaml with latest stable values.
docker_compose_path="docker/docker-compose.yml"
sov="VERSION=${stable_online_version}" yq -i '.services.factorio.build.args[0] = env(sov)' "$docker_compose_path"
sha="SHA256=${stable_sha256}" yq -i '.services.factorio.build.args[1] = env(sha)' "$docker_compose_path"
sha_arm64="SHA256_ARM64=${stable_sha256_arm64}" yq -i '.services.factorio.build.args[2] = env(sha_arm64)' "$docker_compose_path"

git config user.name github-actions[bot]
git config user.email 41898282+github-actions[bot]@users.noreply.github.com

git add buildinfo.json
git add README.md
git add docker/docker-compose.yml
git commit -a -m "Auto Update Factorio to stable version: ${stable_online_version} experimental version: ${experimental_online_version}"

git tag -f latest
git push
git push origin --tags -f
