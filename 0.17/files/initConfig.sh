#!/bin/sh -x
set -e

id

FACTORIO_VOL=/factorio
mkdir -p $FACTORIO_VOL
mkdir -p $SAVES
mkdir -p $CONFIG
mkdir -p $MODS
mkdir -p $SCENARIOS
mkdir -p $SCRIPTOUTPUT

echo "initializing config"

# If there is a /customConfig directory, copy over all stuff from there first
if [ -d $PROVISION ]; then
  echo "custom provisioning data provided, coping over"
  cp -r $PROVISION/* $FACTORIO_VOL 
fi

if [ ! -f $CONFIG/rconpw ]; then
  # Generate a new RCON password if none exists
  echo $(pwgen 15 1) > $CONFIG/rconpw
fi

if [ ! -f $CONFIG/server-settings.json ]; then
  # Copy default settings if server-settings.json doesn't exist
  cp /opt/factorio/data/server-settings.example.json $CONFIG/server-settings.json
fi

if [ ! -f $CONFIG/map-gen-settings.json ]; then
  cp /opt/factorio/data/map-gen-settings.example.json $CONFIG/map-gen-settings.json
fi

if [ ! -f $CONFIG/map-settings.json ]; then
  cp /opt/factorio/data/map-settings.example.json $CONFIG/map-settings.json
fi

if find -L $SAVES -iname \*.tmp.zip -mindepth 1 -print | grep -q .; then
  # Delete incomplete saves (such as after a forced exit)
  rm -f $SAVES/*.tmp.zip
fi

if [ "$(id -u)" = '0' ]; then
  # Take ownership of factorio data if running as root
  chown -R factorio:factorio $FACTORIO_VOL
  # Make sure we own temp
  #mkdir -p /opt/factorio/temp
  #chown -R factorio:factorio /opt/factorio/temp
  # Drop to the factorio user
  SU_EXEC="su-exec factorio"
fi