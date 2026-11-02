#!/bin/bash
# Shared by server entrypoints and the standalone mod updater.
SERVER_ADMINLIST_FILE="${SERVER_ADMINLIST_FILE:-$CONFIG/server-adminlist.json}"
SERVER_BANLIST_FILE="${SERVER_BANLIST_FILE:-$CONFIG/server-banlist.json}"
SERVER_ID_FILE="${SERVER_ID_FILE:-$CONFIG/server-id.json}"
SERVER_SETTINGS_FILE="${SERVER_SETTINGS_FILE:-$CONFIG/server-settings.json}"
SERVER_WHITELIST_FILE="${SERVER_WHITELIST_FILE:-$CONFIG/server-whitelist.json}"

for config_file in "$SERVER_ADMINLIST_FILE" "$SERVER_BANLIST_FILE" "$SERVER_ID_FILE" \
                   "$SERVER_SETTINGS_FILE" "$SERVER_WHITELIST_FILE"; do
  if [[ "$config_file" != /* || "$config_file" == */ || ( -e "$config_file" && ! -f "$config_file" ) ]]; then
    echo "Invalid server config path: $config_file (expected an absolute file path)" >&2
    return 1
  fi
  mkdir -p -- "$(dirname -- "$config_file")"
done
unset config_file

export SERVER_ADMINLIST_FILE SERVER_BANLIST_FILE SERVER_ID_FILE SERVER_SETTINGS_FILE SERVER_WHITELIST_FILE
