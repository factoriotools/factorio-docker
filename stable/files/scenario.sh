#!/bin/bash
set -eoux pipefail

if [[ -z ${1:-} ]]; then
  echo "No argument supplied"
fi

SERVER_SCENARIO="$1"
mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p "$SCENARIOS"

#chown -R factorio /factorio

if [[ ! -f $CONFIG/rconpw ]]; then
  pwgen 15 1 >"$CONFIG/rconpw"
fi

if [[ ! -f $CONFIG/server-settings.json ]]; then
  cp /opt/factorio/data/server-settings.example.json "$CONFIG/server-settings.json"
fi

if [[ ! -f $CONFIG/map-gen-settings.json ]]; then
  cp /opt/factorio/data/map-gen-settings.example.json "$CONFIG/map-gen-settings.json"
fi

if [[ ! -f $CONFIG/map-settings.json ]]; then
  cp /opt/factorio/data/map-settings.example.json "$CONFIG/map-settings.json"
fi

exec /opt/factorio/bin/x64/factorio \
  --port "$PORT" \
  --start-server-load-scenario "$SERVER_SCENARIO" \
  --map-gen-settings "$CONFIG/map-gen-settings.json" \
  --map-settings "$CONFIG/map-settings.json" \
  --server-settings "$CONFIG/server-settings.json" \
  --server-banlist "$CONFIG/server-banlist.json" \
  --server-whitelist "$CONFIG/server-whitelist.json" \
  --use-server-whitelist \
  --server-adminlist "$CONFIG/server-adminlist.json" \
  --rcon-port "$RCON_PORT" \
  --rcon-password "$(cat "$CONFIG/rconpw")" \
  --server-id /factorio/config/server-id.json
