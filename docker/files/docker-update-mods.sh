#!/bin/bash
set -eou pipefail
INSTALLED_DIRECTORY=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/server-config.sh"

if [[ -f /run/secrets/username ]]; then
  USERNAME=$(cat /run/secrets/username)
fi

if [[ -f /run/secrets/token ]]; then
  TOKEN=$(cat /run/secrets/token)
fi

if [[ -z ${USERNAME:-} ]]; then
  USERNAME="$(jq -j ".username" "$SERVER_SETTINGS_FILE")"
fi

if [[ -z ${TOKEN:-} ]]; then
  TOKEN="$(jq -j ".token" "$SERVER_SETTINGS_FILE")"
fi

if [[ -z ${USERNAME:-} ]]; then
  echo "You need to provide your Factorio username to update mods."
fi

if [[ -z ${TOKEN:-} ]]; then
  echo "You need to provide your Factorio token to update mods."
fi

./update-mods.sh "$VERSION" "$MODS" "$USERNAME" "$TOKEN" "${UPDATE_IGNORE:-}"
