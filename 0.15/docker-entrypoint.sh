#!/bin/sh -x

set -e

SAVES=/factorio/saves
CONFIG=/factorio/config

mkdir -p $SAVES
mkdir -p /factorio/mods
mkdir -p $CONFIG

if [ ! -f $CONFIG/rconpw ]; then
  echo $(pwgen 15 1) > $CONFIG/rconpw
fi

if [ ! -f $CONFIG/server-settings.json ]; then
  cp /opt/factorio/data/server-settings.example.json $CONFIG/server-settings.json
fi

if [ ! -f $CONFIG/map-gen-settings.json ]; then
  cp /opt/factorio/data/map-gen-settings.example.json $CONFIG/map-gen-settings.json
fi

if [ ! -f $CONFIG/map-settings.json ]; then
  cp /opt/factorio/data/map-settings.example.json $CONFIG/map-settings.json
fi

# generate new map if no save exists
if ! find -L $SAVES -iname \*.zip -mindepth 1 -print | grep -q .; then
  /opt/factorio/bin/x64/factorio \
    --create $SAVES/_autosave1.zip  \
    --map-gen-settings $CONFIG/map-gen-settings.json \
    --map-settings $CONFIG/map-settings.json
fi

if [ $# -eq 0 ]; then
  # run factorio with default params in no options specified
  exec /opt/factorio/bin/x64/factorio \
    --port $PORT \
    --start-server-load-latest \
    --server-settings $CONFIG/server-settings.json \
    --server-whitelist $CONFIG/server-whitelist.json \
    --server-banlist $CONFIG/server-banlist.json \
    --rcon-port 27015 \
    --rcon-password "$(cat $CONFIG/rconpw)" \
    --server-id /factorio/config/server-id.json
else
  # run factorio with user specified params
  exec /opt/factorio/bin/x64/factorio "$@"
fi
