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

# Create directories if they don't exist
# In rootless mode, these should be writable by the container user
mkdir -p "$FACTORIO_VOL"
mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p "$SCENARIOS"
mkdir -p "$SCRIPTOUTPUT"

# Generate RCON password if needed
if [[ ! -f $CONFIG/rconpw ]]; then
  pwgen 15 1 >"$CONFIG/rconpw"
fi

# Copy default configs if they don't exist
if [[ ! -f $CONFIG/server-settings.json ]]; then
  cp /opt/factorio/data/server-settings.example.json "$CONFIG/server-settings.json"
fi

if [[ ! -f $CONFIG/map-gen-settings.json ]]; then
  cp /opt/factorio/data/map-gen-settings.example.json "$CONFIG/map-gen-settings.json"
fi

if [[ ! -f $CONFIG/map-settings.json ]]; then
  cp /opt/factorio/data/map-settings.example.json "$CONFIG/map-settings.json"
fi

# Clean up incomplete saves
NRTMPSAVES=$( find -L "$SAVES" -iname \*.tmp.zip -mindepth 1 | wc -l )
if [[ $NRTMPSAVES -gt 0 ]]; then
  rm -f "$SAVES"/*.tmp.zip
fi

# Update mods if requested
if [[ ${UPDATE_MODS_ON_START:-} == "true" ]]; then
  ${INSTALLED_DIRECTORY}/docker-update-mods.sh
fi

# Handle DLC
${INSTALLED_DIRECTORY}/docker-dlc.sh

# In rootless mode, we don't need to handle user switching or chown
# The container runs as the specified user from the start
EXEC=""
if [[ -f /bin/box64 ]]; then
  # Use emulator for ARM hosts
  EXEC="/bin/box64"
fi

# Update config path
sed -i '/write-data=/c\write-data=\/factorio/' /opt/factorio/config/config.ini

# Generate new save if needed
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
        if [[ ! -z "$PRESET" ]]; then
            $EXEC /opt/factorio/bin/x64/factorio \
                --create "$SAVES/$SAVE_NAME.zip" \
                --preset "$PRESET" \
                --map-gen-settings "$CONFIG/map-gen-settings.json" \
                --map-settings "$CONFIG/map-settings.json"
        else
            $EXEC /opt/factorio/bin/x64/factorio \
                --create "$SAVES/$SAVE_NAME.zip" \
                --map-gen-settings "$CONFIG/map-gen-settings.json" \
                --map-settings "$CONFIG/map-settings.json"
        fi
    fi
fi

# Build command flags
FLAGS=(\
  --port "$PORT" \
  --server-settings "$CONFIG/server-settings.json" \
  --server-banlist "$CONFIG/server-banlist.json" \
  --rcon-port "$RCON_PORT" \
  --server-whitelist "$CONFIG/server-whitelist.json" \
  --use-server-whitelist \
  --server-adminlist "$CONFIG/server-adminlist.json" \
  --rcon-password "$(cat "$CONFIG/rconpw")" \
  --server-id /factorio/config/server-id.json \
  --mod-directory "$MODS" \
)

if [ -n "$CONSOLE_LOG_LOCATION" ]; then
  FLAGS+=( --console-log "$CONSOLE_LOG_LOCATION" )
fi

if [ -n "$BIND" ]; then
  FLAGS+=( --bind "$BIND" )
fi

if [[ $LOAD_LATEST_SAVE == true ]]; then
    FLAGS+=( --start-server-load-latest )
else
    FLAGS+=( --start-server "$SAVE_NAME" )
fi

# Execute factorio
# In rootless mode, we run directly without user switching
exec $EXEC /opt/factorio/bin/x64/factorio "${FLAGS[@]}" "$@"