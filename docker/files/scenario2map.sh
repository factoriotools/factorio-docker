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
  --scenario2map "$SERVER_SCENARIO"
