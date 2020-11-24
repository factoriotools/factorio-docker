#!/bin/bash
set -eou pipefail

if [[ -f /run/secrets/username ]]; then
  USERNAME=$(cat /run/secrets/username)
fi

if [[ -f /run/secrets/token ]]; then
  TOKEN=$(cat /run/secrets/token)
fi

if [[ -z ${USERNAME:-} ]]; then
  USERNAME="$(jq -j ".username" "$CONFIG/server-settings.json")"
fi

if [[ -z ${TOKEN:-} ]]; then
  TOKEN="$(jq -j ".token" "$CONFIG/server-settings.json")"
fi

if [[ -z ${USERNAME:-} ]]; then
  echo "You need to provide your Factorio username to update mods."
fi

if [[ -z ${TOKEN:-} ]]; then
  echo "You need to provide your Factorio token to update mods."
fi

./update-mods.sh "$VERSION" "$MODS" "$USERNAME" "$TOKEN"
