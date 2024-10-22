#!/bin/bash
set -eou pipefail

# Path to the mod-list.json file
MOD_LIST_FILE="$MODS/mod-list.json"

enable_mod()
{
  echo "Enable mod $1 for DLC"
  jq --arg mod_name "$1" 'if .mods | map(.name) | index($mod_name) then .mods |= map(if .name == $mod_name and .enabled == false then .enabled = true else . end) else . end' "$MOD_LIST_FILE" > "$MOD_LIST_FILE.tmp"
  mv "$MOD_LIST_FILE.tmp" "$MOD_LIST_FILE"
}

disable_mod()
{
  echo "Disable mod $1 for DLC"
  jq --arg mod_name "$1" 'if .mods | map(.name) | index($mod_name) then .mods |= map(if .name == $mod_name and .enabled == true then .enabled = false else . end) else .mods += [{"name": $mod_name, "enabled": false}] end' "$MOD_LIST_FILE" > "$MOD_LIST_FILE.tmp"
  mv "$MOD_LIST_FILE.tmp" "$MOD_LIST_FILE"
}

# Enable or disable DLCs if configured
if [[ ${DLC_SPACE_AGE:-} == "true" ]]; then
  # Define the DLC mods
  DLC_MODS=("elevated-rails" "quality" "space-age")

  # Iterate over each DLC mod
  for MOD in "${DLC_MODS[@]}"; do
    enable_mod "$MOD"
  done
else
  # Define the DLC mods
  DLC_MODS=("elevated-rails" "quality" "space-age")

  # Iterate over each DLC mod
  for MOD in "${DLC_MODS[@]}"; do
    disable_mod "$MOD"
  done
fi
