#!/usr/bin/env bats

# Runs the real update.sh with curl, git and yq replaced by fakes that log their calls.
setup() {
  UPDATE="$BATS_TEST_DIRNAME/../update.sh"
  cd "$BATS_TEST_TMPDIR" || return
  mkdir -p bin docker
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH" FAIL_URL=""
  printf '<!-- start autogeneration tags -->\nold\n<!-- end autogeneration tags -->\n' > README.md
  printf '%s\n' '{"2.0.76":{"sha256":"old","tags":["latest","stable"]}}' > buildinfo.json
  cat > bin/curl <<'EOF'
#!/bin/sh
echo "$1" >> curl-calls
if [ -n "$FAIL_URL" ] && [ "${1#*"$FAIL_URL"}" != "$1" ]; then exit 6; fi
case "$1" in
  *latest-releases) cat releases.json ;;
  *sha256sums/) cat sums.txt ;;
  *) exit 99 ;;
esac
EOF
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> git-calls\n' > bin/git
  printf '#!/bin/sh\nprintf "%%s\\n" "${sov:-}${sha:-}${sha_arm64:-}" >> compose-args\n' > bin/yq
  chmod +x bin/*
}

# releases STABLE EXPERIMENTAL [VERSION...]: versions listed after the first two also get ARM64 checksums.
releases() {
  local stable=$1 experimental=$2 version
  shift 2
  printf '{"stable":{"headless":"%s"},"experimental":{"headless":"%s"}}\n' "$stable" "$experimental" > releases.json
  : > sums.txt
  for version in $(printf '%s\n' "$stable" "$experimental" | sort -u); do
    printf 'x64-%s  factorio-headless_linux_%s.tar.xz\n' "$version" "$version" >> sums.txt
  done
  for version in "$@"; do
    printf 'arm-%s  factorio-headless_linux-arm64_%s.tar.xz\n' "$version" "$version" >> sums.txt
  done
}

readme_tags() {
  sed -n '/start autogeneration tags/,/end autogeneration tags/p' README.md | sed '1d;$d' | sed '/^$/d'
}

@test "each release list is downloaded once" {
  releases 2.0.77 2.1.24 2.1.24
  run bash "$UPDATE"
  [ "$status" -eq 0 ]
  [ "$(sort curl-calls)" = "https://factorio.com/api/latest-releases
https://factorio.com/download/sha256sums/" ]
}

@test "stable and experimental on different branches get separate tags" {
  releases 2.0.77 2.1.24 2.1.24
  run bash "$UPDATE"
  [ "$status" -eq 0 ]
  [ "$(jq -c '."2.0.77"' buildinfo.json)" = '{"sha256":"x64-2.0.77","tags":["stable","stable-2.0.77","2","2.0","2.0.77"]}' ]
  [ "$(jq -c '."2.1.24"' buildinfo.json)" = '{"sha256":"x64-2.1.24","sha256_arm64":"arm-2.1.24","tags":["latest","2","2.1","2.1.24"]}' ]
  [ "$(readme_tags)" = '* `latest, 2.1.24`
* `2, 2.0, 2.0.77, stable, stable-2.0.77`' ]
  [ "$(cat compose-args)" = "VERSION=2.0.77
SHA256=x64-2.0.77
SHA256_ARM64=" ]
}

@test "stable and experimental on the same branch share major and minor tags with stable" {
  releases 2.1.23 2.1.24 2.1.23 2.1.24
  run bash "$UPDATE"
  [ "$status" -eq 0 ]
  [ "$(jq -c '."2.1.23".tags' buildinfo.json)" = '["stable","stable-2.1.23","2","2.1","2.1.23"]' ]
  [ "$(jq -c '."2.1.24".tags' buildinfo.json)" = '["latest","2.1.24"]' ]
  [ "$(readme_tags)" = '* `latest, 2.1.24`
* `2, 2.1, 2.1.23, stable, stable-2.1.23`' ]
  [ "$(sed -n 3p compose-args)" = "SHA256_ARM64=arm-2.1.23" ]
}

@test "one version that is both stable and latest gets one entry and one README line" {
  releases 2.1.24 2.1.24 2.1.24
  run bash "$UPDATE"
  [ "$status" -eq 0 ]
  [ "$(jq -c . buildinfo.json)" = '{"2.1.24":{"sha256":"x64-2.1.24","sha256_arm64":"arm-2.1.24","tags":["latest","stable","stable-2.1.24","2","2.1","2.1.24"]}}' ]
  [ "$(readme_tags)" = '* `latest, 2.1.24`' ]
}

@test "an update commits, moves the latest tag and pushes" {
  releases 2.1.24 2.1.24 2.1.24
  run bash "$UPDATE"
  [ "$status" -eq 0 ]
  grep -Fxq 'commit -a -m Auto Update Factorio to stable version: 2.1.24 experimental version: 2.1.24' git-calls
  grep -Fxq 'tag -f latest' git-calls
  grep -Fxq 'push' git-calls
  grep -Fxq 'push origin --tags -f' git-calls
}

@test "unchanged releases change nothing and push nothing" {
  releases 2.1.24 2.1.24 2.1.24
  printf '%s\n' '{"2.1.24":{"sha256":"x64-2.1.24","tags":["latest","stable"]}}' > buildinfo.json
  cp buildinfo.json before.json
  cp README.md before.md
  run bash "$UPDATE"
  [ "$status" -eq 0 ]
  cmp -s buildinfo.json before.json
  cmp -s README.md before.md
  [ ! -e git-calls ]
  [ ! -e compose-args ]
}

@test "a failed checksum download stops before writing or pushing" {
  releases 2.1.24 2.1.24 2.1.24
  cp buildinfo.json before.json
  FAIL_URL=sha256sums run bash "$UPDATE"
  [ "$status" -eq 6 ]
  cmp -s buildinfo.json before.json
  [ ! -e git-calls ]
}

@test "a failed release list download stops before writing or pushing" {
  releases 2.1.24 2.1.24 2.1.24
  cp buildinfo.json before.json
  FAIL_URL=latest-releases run bash "$UPDATE"
  [ "$status" -eq 6 ]
  cmp -s buildinfo.json before.json
  [ ! -e git-calls ]
}
