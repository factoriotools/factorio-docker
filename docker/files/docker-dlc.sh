#!/bin/bash
set -eou pipefail

# Path to the mod-list.json file
MOD_LIST_FILE="$MODS/mod-list.json"

ALL_SPACE_AGE_MODS=("elevated-rails" "quality" "space-age")

if [[ ! -f "$MOD_LIST_FILE" ]]; then
  # Create the mod-list.json file if it doesn't exist
  echo '{"mods":[{"name":"base","enabled":true}]}' > "$MOD_LIST_FILE"
fi

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
  ENABLE_MODS=(${ALL_SPACE_AGE_MODS[@]})
elif [[ ${DLC_SPACE_AGE:-} == "false" ]]; then
  # Define the DLC mods
  DISABLE_MODS=(${ALL_SPACE_AGE_MODS[@]})
else
  ENABLE_MODS=()
  DISABLE_MODS=()

  for SPACE_AGE_MOD in "${ALL_SPACE_AGE_MODS[@]}"; do
    REGEX="(^|\s)$SPACE_AGE_MOD($|\s)"
    if [[ "$DLC_SPACE_AGE" =~ $REGEX ]]; then
      ENABLE_MODS+=($SPACE_AGE_MOD)
    else
      DISABLE_MODS+=($SPACE_AGE_MOD)
    fi
  done
fi

# Iterate over each DLC mod to enable
for MOD in "${ENABLE_MODS[@]}"; do
  enable_mod "$MOD"
done

# Iterate over each DLC mod to disable
for MOD in "${DISABLE_MODS[@]}"; do
  disable_mod "$MOD"
done
