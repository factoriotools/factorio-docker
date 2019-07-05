#!/bin/bash

if [[ -f /run/secrets/username ]]; then
  USERNAME=$(cat /run/secrets/username)
fi

if [[ -f /run/secrets/username ]]; then
  TOKEN=$(cat /run/secrets/token)
fi

if [[ -z $TOKEN ]]; then
  set -- "$(jq -j ".username, \" \", .token" "$CONFIG/server-settings.json")"
  USERNAME=$1
  TOKEN=$2
fi

./update-mods.sh "$VERSION" "$MODS" "$USERNAME" "$TOKEN"
