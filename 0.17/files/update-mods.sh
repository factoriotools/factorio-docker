#!/bin/bash
set -eou pipefail

FACTORIO_VERSION=$1
MOD_DIR=$2
USERNAME=$3
TOKEN=$4

MOD_BASE_URL="https://mods.factorio.com"

print_step()
{
  echo "$1"
}

print_success()
{
  echo "$1"
}

print_failure()
{
  echo "$1"
}

update_mod()
{
  MOD_NAME="$1"
  MOD_NAME_ENCODED="${1// /%20}"

  print_step "Checking for update of mod $MOD_NAME..."

  MOD_INFO_URL="$MOD_BASE_URL/api/mods/$MOD_NAME_ENCODED"
  MOD_INFO_JSON=$(curl --silent "$MOD_INFO_URL")

  if ! echo "$MOD_INFO_JSON" | jq -e .name >/dev/null; then
    print_success "  Custom mod not on $MOD_BASE_URL, skipped."
    return 0
  fi

  MOD_INFO=$(echo "$MOD_INFO_JSON" | jq -j --arg version "$FACTORIO_VERSION" ".releases|reverse|map(select(.info_json.factorio_version as \$mod_version | \$version | startswith(\$mod_version)))[0]|.file_name, \";\", .download_url, \";\", .sha1")

  MOD_FILENAME=$(echo "$MOD_INFO" | cut -f1 -d";")
  MOD_URL=$(echo "$MOD_INFO" | cut -f2 -d";")
  MOD_SHA1=$(echo "$MOD_INFO" | cut -f3 -d";")

  if [[ $MOD_FILENAME == null ]]; then
    print_failure "  Not compatible with version"
    return 0
  fi

  if [[ -f $MOD_DIR/$MOD_FILENAME ]]; then
    print_success "  Already up-to-date."
    return 0
  fi

  print_step "Downloading..."
  FULL_URL="$MOD_BASE_URL$MOD_URL?username=$USERNAME&token=$TOKEN"
  HTTP_STATUS=$(curl --silent -L -w "%{http_code}" -o "$MOD_DIR/$MOD_FILENAME" "$FULL_URL")

  if [[ $HTTP_STATUS != 200 ]]; then
    print_failure "  Download failed: Code $HTTP_STATUS."
    rm -f "$MOD_DIR/$MOD_FILENAME"
    return 1
  fi

  if [[ ! -f $MOD_DIR/$MOD_FILENAME ]]; then
    print_failure "  Downloaded file missing!"
    return 1
  fi

  if ! [[ $(sha1sum "$MOD_DIR/$MOD_FILENAME") =~ $MOD_SHA1 ]]; then
    print_failure "  SHA1 mismatch!"
    rm -f "$MOD_DIR/$MOD_FILENAME"
    return 1
  fi

  print_success "  Download complete."

  for file in "$MOD_DIR/${MOD_NAME}_"*".zip"; do # wildcard does usually not work in quotes: https://unix.stackexchange.com/a/67761
    if [[ $file != $MOD_DIR/$MOD_FILENAME ]]; then
      print_success "  Deleting old version: $file"
      rm -f "$file"
    fi
  done

  return 0
}

if [[ -f $MOD_DIR/mod-list.json ]]; then
  jq -r ".mods|map(select(.enabled))|.[].name" "$MOD_DIR/mod-list.json" | while read -r mod; do
    if [[ $mod != base ]]; then
      update_mod "$mod"
    fi
  done
fi
