#!/bin/bash
set -eoux pipefail

FACTORIO_VOL=/factorio
LOAD_LATEST_SAVE="${LOAD_LATEST_SAVE:-true}"
GENERATE_NEW_SAVE="${GENERATE_NEW_SAVE:-false}"
SAVE_NAME="${SAVE_NAME:-""}"

mkdir -p "$FACTORIO_VOL"
mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p "$SCENARIOS"
mkdir -p "$SCRIPTOUTPUT"

# Initialize Factorio server configuration files location variables..."
SERVER_SETTINGS_FILE="${SERVER_SETTINGS_FILE:$CONFIG/server-settings.json}"
SERVER_ID_FILE="${SERVER_ID_FILE:$CONFIG/server-id.json}"
ADMINLIST_FILE="${ADMINLIST_FILE:-$CONFIG/server-adminlist.json}"
WHITELIST_FILE="${WHITELIST_FILE:-$CONFIG/server-whitelist.json}"
BANLIST_FILE="${BANLIST_FILE:-$CONFIG/server-banlist.json}"
echo "SERVER_SETTINGS_FILE=$SERVER_SETTINGS_FILE"
echo "SERVER_ID_FILE=$SERVER_ID_FILE"
echo "ADMINLIST_FILE=$ADMINLIST_FILE"
echo "WHITELIST_FILE=$WHITELIST_FILE"
echo "BANLIST_FILE=$BANLIST_FILE"
mkdir -p "$SERVER_SETTINGS_FILE"
mkdir -p "$SERVER_ID_FILE"
mkdir -p "$ADMINLIST_FILE"
mkdir -p "$WHITELIST_FILE"
mkdir -p "$BANLIST_FILE"


if [[ ! -f $CONFIG/rconpw ]]; then
  # Generate a new RCON password if none exists
  pwgen 15 1 >"$CONFIG/rconpw"
fi

if [[ ! -f $CONFIG/server-settings.json ]]; then
  # Copy default settings if server-settings.json doesn't exist
  cp /opt/factorio/data/server-settings.example.json "$CONFIG/server-settings.json"
fi

if [[ ! -f $CONFIG/map-gen-settings.json ]]; then
  cp /opt/factorio/data/map-gen-settings.example.json "$CONFIG/map-gen-settings.json"
fi

if [[ ! -f $CONFIG/map-settings.json ]]; then
  cp /opt/factorio/data/map-settings.example.json "$CONFIG/map-settings.json"
fi

NRTMPSAVES=$( find -L "$SAVES" -iname \*.tmp.zip -mindepth 1 | wc -l )
if [[ $NRTMPSAVES -gt 0 ]]; then
  # Delete incomplete saves (such as after a forced exit)
  rm -f "$SAVES"/*.tmp.zip
fi

if [[ ${UPDATE_MODS_ON_START:-} == "true" ]]; then
  ./docker-update-mods.sh
fi

if [[ $(id -u) = 0 ]]; then
  # Update the User and Group ID based on the PUID/PGID variables
  usermod -o -u "$PUID" factorio
  groupmod -o -g "$PGID" factorio
  # Take ownership of factorio data if running as root
  chown -R factorio:factorio "$FACTORIO_VOL"
  # Drop to the factorio user
  SU_EXEC="su-exec factorio"
else
  SU_EXEC=""
fi

sed -i '/write-data=/c\write-data=\/factorio/' /opt/factorio/config/config.ini

NRSAVES=$(find -L "$SAVES" -iname \*.zip -mindepth 1 | wc -l)
if [[ $GENERATE_NEW_SAVE != true && $NRSAVES ==  0 ]]; then
    GENERATE_NEW_SAVE=true
    SAVE_NAME=_autosave1
fi

if [[ $GENERATE_NEW_SAVE == true ]]; then
    if [[ -z "$SAVE_NAME" ]]; then
        echo "If \$GENERATE_NEW_SAVE is true, you must specify \$SAVE_NAME"
        exit 1
    fi
    if [[ -f "$SAVES/$SAVE_NAME.zip" ]]; then
        echo "Map $SAVES/$SAVE_NAME.zip already exists, skipping map generation"
    else
        $SU_EXEC /opt/factorio/bin/x64/factorio \
            --create "$SAVES/$SAVE_NAME.zip" \
            --map-gen-settings "$CONFIG/map-gen-settings.json" \
            --map-settings "$CONFIG/map-settings.json"
    fi
fi

FLAGS=(\
  --port "$PORT" \
  --server-settings "$SERVER_SETTINGS_FILE" \
  --server-banlist "$SERVER_ID_FILE" \
  --rcon-port "$RCON_PORT" \
  --server-whitelist "$ADMINLIST_FILE" \
  --use-server-whitelist \
  --server-adminlist "$WHITELIST_FILE" \
  --rcon-password "$(cat "$CONFIG/rconpw")" \
  --server-id "$BANLIST_FILE" \
)

if [[ $LOAD_LATEST_SAVE == true ]]; then
    FLAGS+=( --start-server-load-latest )
else
    FLAGS+=( --start-server "$SAVE_NAME" )
fi

# shellcheck disable=SC2086
exec $SU_EXEC /opt/factorio/bin/x64/factorio "${FLAGS[@]}" "$@"
