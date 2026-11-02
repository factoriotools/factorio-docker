#!/bin/bash
set -eoux pipefail
INSTALLED_DIRECTORY=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
FACTORIO_VOL=/factorio
LOAD_LATEST_SAVE="${LOAD_LATEST_SAVE:-true}"
GENERATE_NEW_SAVE="${GENERATE_NEW_SAVE:-false}"
PRESET="${PRESET:-""}"
SAVE_NAME="${SAVE_NAME:-""}"
BIND="${BIND:-""}"
CONSOLE_LOG_LOCATION="${CONSOLE_LOG_LOCATION:-""}"

mkdir -p "$FACTORIO_VOL"
mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p "$SCENARIOS"

# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/server-config.sh"
mkdir -p "$SCRIPTOUTPUT"

if [[ ! -f $CONFIG/rconpw ]]; then
  # Generate a new RCON password if none exists
  pwgen 15 1 >"$CONFIG/rconpw"
fi

if [[ ! -f $SERVER_SETTINGS_FILE ]]; then
  # Copy default settings if server-settings.json doesn't exist
  cp /opt/factorio/data/server-settings.example.json "$SERVER_SETTINGS_FILE"
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
  "${INSTALLED_DIRECTORY}"/docker-update-mods.sh
fi

"${INSTALLED_DIRECTORY}"/docker-dlc.sh

EXEC=""
if [[ $(id -u) == 0 ]]; then
  # Update the User and Group ID based on the PUID/PGID variables
  usermod -o -u "$PUID" factorio
  groupmod -o -g "$PGID" factorio
  # Take ownership of factorio data if running as root
  chown -R factorio:factorio "$FACTORIO_VOL"
  # Replace the process when dropping privileges; runuser kills slow saves after SIGTERM.
  EXEC="setpriv --reuid=factorio --regid=factorio --init-groups --"
fi

# Setup ARM64 emulation support
# shellcheck disable=SC1091
source "${INSTALLED_DIRECTORY}/setup-exec.sh"

sed -i '/write-data=/c\write-data=\/factorio/' /opt/factorio/config/config.ini

NRSAVES=$(find -L "$SAVES" -iname \*.zip -mindepth 1 | wc -l)
if [[ $GENERATE_NEW_SAVE != true && $NRSAVES ==  0 ]]; then
    GENERATE_NEW_SAVE=true
    SAVE_NAME="${SAVE_NAME:-_autosave1}"
fi

if [[ "$SAVE_NAME" == /* ]]; then
    SAVE_FILE="$SAVE_NAME"
else
    SAVE_FILE="$SAVES/${SAVE_NAME%.zip}.zip"
fi

if [[ $GENERATE_NEW_SAVE == true ]]; then
    if [[ -z "$SAVE_NAME" ]]; then
        echo "If \$GENERATE_NEW_SAVE is true, you must specify \$SAVE_NAME"
        exit 1
    fi
    if [[ -f "$SAVE_FILE" ]]; then
        echo "Map $SAVE_FILE already exists, skipping map generation"
    else
        if [[ -n "$PRESET" ]]; then
            $EXEC /opt/factorio/bin/x64/factorio \
                --create "$SAVE_FILE" \
                --preset "$PRESET" \
                --map-gen-settings "$CONFIG/map-gen-settings.json" \
                --map-settings "$CONFIG/map-settings.json"
        else
            $EXEC /opt/factorio/bin/x64/factorio \
                --create "$SAVE_FILE" \
                --map-gen-settings "$CONFIG/map-gen-settings.json" \
                --map-settings "$CONFIG/map-settings.json"
        fi
    fi
fi

FLAGS=(\
  --server-settings "$SERVER_SETTINGS_FILE" \
  --server-banlist "$SERVER_BANLIST_FILE" \
  --rcon-port "$RCON_PORT" \
  --server-whitelist "$SERVER_WHITELIST_FILE" \
  --use-server-whitelist \
  --server-adminlist "$SERVER_ADMINLIST_FILE" \
  --rcon-password "$(cat "$CONFIG/rconpw")" \
  --server-id "$SERVER_ID_FILE" \
  --mod-directory "$MODS" \
)

if [ -n "$CONSOLE_LOG_LOCATION" ]; then
  FLAGS+=( --console-log "$CONSOLE_LOG_LOCATION" )
fi

if [ -n "$BIND" ]; then
  FLAGS+=( --bind "$BIND" )
fi

# An explicit bind port wins; bare IPv6 addresses still use PORT.
if [[ ! "$BIND" =~ ^[^:]+:[0-9]+$ && ! "$BIND" =~ ^\[[^]]+\]:[0-9]+$ ]]; then
  FLAGS+=( --port "$PORT" )
fi

if [[ $LOAD_LATEST_SAVE == true ]]; then
    FLAGS+=( --start-server-load-latest )
else
    if [[ -z "$SAVE_NAME" || ! -f "$SAVE_FILE" ]]; then
        echo "Selected save does not exist: $SAVE_FILE. Set SAVE_NAME or GENERATE_NEW_SAVE=true." >&2
        exit 1
    fi
    FLAGS+=( --start-server "$SAVE_FILE" )
fi

# shellcheck disable=SC2086
exec $EXEC /opt/factorio/bin/x64/factorio "${FLAGS[@]}" "$@"
