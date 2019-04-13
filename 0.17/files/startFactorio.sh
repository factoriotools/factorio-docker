#!/bin/sh -x
if [ -z "$1" ]
  then
    echo "No argument supplied"
fi
CMD=$1


exec ${SU_EXEC} /opt/factorio/bin/x64/factorio \
  --port $PORT \
  --$CMD \
  --server-settings $CONFIG/server-settings.json \
  --server-banlist $CONFIG/server-banlist.json \
  --rcon-port $RCON_PORT \
  --server-whitelist $CONFIG/server-whitelist.json \
  --use-server-whitelist \
  --server-adminlist $CONFIG/server-adminlist.json \
  --rcon-password "$(cat $CONFIG/rconpw)" \
  --server-id /factorio/config/server-id.json \
  "$@"
