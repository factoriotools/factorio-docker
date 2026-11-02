#!/bin/bash
set -eoux pipefail
INSTALLED_DIRECTORY=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

if [[ -z ${1:-} ]]; then
  echo "No argument supplied"
fi

SERVER_SCENARIO="$1"
mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p "$SCENARIOS"

# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/server-config.sh"

if [[ ! -f $SERVER_SETTINGS_FILE ]]; then
  cp /opt/factorio/data/server-settings.example.json "$SERVER_SETTINGS_FILE"
fi

if [[ ! -f $CONFIG/map-gen-settings.json ]]; then
  cp /opt/factorio/data/map-gen-settings.example.json "$CONFIG/map-gen-settings.json"
fi

if [[ ! -f $CONFIG/map-settings.json ]]; then
  cp /opt/factorio/data/map-settings.example.json "$CONFIG/map-settings.json"
fi

# Setup ARM64 emulation support
EXEC=""
# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/setup-exec.sh"

exec $EXEC /opt/factorio/bin/x64/factorio \
  --scenario2map "$SERVER_SCENARIO"
