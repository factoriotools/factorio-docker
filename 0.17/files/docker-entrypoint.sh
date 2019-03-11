#!/bin/sh -x
set -e

sh /initConfig.sh

if ! find -L $SAVES -iname \*.zip -mindepth 1 -print | grep -q .; then
  # Generate a new map if no save ZIPs exist
  ${SU_EXEC} /opt/factorio/bin/x64/factorio \
    --create $SAVES/_autosave1.zip  \
    --map-gen-settings $CONFIG/map-gen-settings.json \
    --map-settings $CONFIG/map-settings.json
fi

sh /startFactorio.sh start-server-load-latest
