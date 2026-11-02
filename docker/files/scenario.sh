#!/bin/bash
set -eoux pipefail
INSTALLED_DIRECTORY=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

if [[ -z ${1:-} ]]; then
  echo "No argument supplied"
fi

SERVER_SCENARIO="$1"
PRESET="${PRESET:-""}"

mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p "$SCENARIOS"

# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/server-config.sh"

#chown -R factorio /factorio

if [[ ! -f $CONFIG/rconpw ]]; then
  pwgen 15 1 >"$CONFIG/rconpw"
fi

if [[ ! -f $SERVER_SETTINGS_FILE ]]; then
  cp /opt/factorio/data/server-settings.example.json "$SERVER_SETTINGS_FILE"
fi

if [[ ! -f $CONFIG/map-gen-settings.json ]]; then
  cp /opt/factorio/data/map-gen-settings.example.json "$CONFIG/map-gen-settings.json"
fi

if [[ ! -f $CONFIG/map-settings.json ]]; then
  cp /opt/factorio/data/map-settings.example.json "$CONFIG/map-settings.json"
fi

"${INSTALLED_DIRECTORY}"/docker-dlc.sh

# Setup ARM64 emulation support
EXEC=""
# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/setup-exec.sh"

exec $EXEC /opt/factorio/bin/x64/factorio \
  --port "$PORT" \
  --start-server-load-scenario "$SERVER_SCENARIO" \
  --preset "$PRESET" \
  --map-gen-settings "$CONFIG/map-gen-settings.json" \
  --map-settings "$CONFIG/map-settings.json" \
  --server-settings "$SERVER_SETTINGS_FILE" \
  --server-banlist "$SERVER_BANLIST_FILE" \
  --server-whitelist "$SERVER_WHITELIST_FILE" \
  --use-server-whitelist \
  --server-adminlist "$SERVER_ADMINLIST_FILE" \
  --rcon-port "$RCON_PORT" \
  --rcon-password "$(cat "$CONFIG/rconpw")" \
  --server-id "$SERVER_ID_FILE"
