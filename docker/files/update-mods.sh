#!/bin/bash
set -eou pipefail

FACTORIO_VERSION=$1
MOD_DIR=$2
USERNAME=$3
TOKEN=$4
UPDATE_IGNORE=$5

MOD_BASE_URL="https://mods.factorio.com"

print_step()
{
  echo "$1"
}

print_success()
{
  echo "$1"
}

print_failure()
{
  echo "$1"
}

# Checks if the current game version satisfies the mod's minimum required version.
# Returns 1 if the game version is compatible with the mod, 0 if not
check_game_version() {
  local mod_required_version="$1"  # The minimum Factorio version required by the mod
  local current_game_version="$2"  # The current Factorio version

  local mod_major mod_minor game_major game_minor
  mod_major=$(echo "$mod_required_version" | cut -d '.' -f1)
  mod_minor=$(echo "$mod_required_version" | cut -d '.' -f2)
  game_major=$(echo "$current_game_version" | cut -d '.' -f1)
  game_minor=$(echo "$current_game_version" | cut -d '.' -f2)

  # If game major version is greater than mod's required major version, it's compatible
  if [[ "$game_major" -gt "$mod_major" ]]; then
    echo 1
    return
  fi

  # If game major version is less than mod's required major version, it's not compatible
  if [[ "$game_major" -lt "$mod_major" ]]; then
    echo 0
    return
  fi

  # Major versions are equal, check minor versions
  # Game minor version must be >= mod's required minor version
  if [[ "$game_minor" -ge "$mod_minor" ]]; then
    echo 1
  else
    echo 0
  fi
}

# Checks dependency string with provided version.
# Only checks for operator based string, ignoring everything else
# Returns 1 if check is ok, 0 if not
check_dependency_version()
{
  local dependency="$1"
  local mod_version="$2"

  if [[ "$dependency" =~ ^(\?|!|~|\(~\)) ]]; then
    echo 1
  fi

  local condition
  condition=$(echo "$dependency" | grep -oE '(>=|<=|>|<|=) [0-9]+(\.[0-9]+)*')

  if [[ -z "$condition" ]]; then
    echo 1
  fi

  local operator required_version
  operator=$(echo "$condition" | awk '{print $1}')
  required_version=$(echo "$condition" | awk '{print $2}')

  case "$operator" in
    ">=")
      if [[ "$(printf '%s\n%s\n' "$required_version" "$mod_version" | sort -V | head -n1)" == "$required_version" ]]; then
        echo 1
      else
        echo 0
      fi
      ;;
    ">")
      if [[ "$(printf '%s\n%s\n' "$required_version" "$mod_version" | sort -V | head -n1)" == "$required_version" && "$required_version" != "$mod_version" ]]; then
        echo 1
      else
        echo 0
      fi
      ;;
    "<=")
      if [[ "$(printf '%s\n%s\n' "$required_version" "$mod_version" | sort -V | tail -n1)" == "$required_version" ]]; then
        echo 1
      else
        echo 0
      fi
      ;;
    "<")
      if [[ "$(printf '%s\n%s\n' "$required_version" "$mod_version" | sort -V | tail -n1)" == "$required_version" && "$required_version" != "$mod_version" ]]; then
        echo 1
      else
        echo 0
      fi
      ;;
    "=")
      if [[ "$mod_version" == "$required_version" ]]; then
        echo 1
      else
        echo 0
      fi
      ;;
    *)
      echo 0
      ;;
  esac
}

get_mod_info()
{
  local mod_info_json="$1"

  # Process mod releases from newest to oldest, looking for a compatible version
  while IFS= read -r mod_release_info; do
    local mod_version mod_factorio_version
    mod_version=$(echo "$mod_release_info" | jq -r ".version")
    mod_factorio_version=$(echo "$mod_release_info" | jq -r ".info_json.factorio_version")

    # Check if this mod version is compatible with our Factorio version
    # This prevents downloading mods that require a newer Factorio version (fixes #468)
    # and ensures backward compatibility (e.g., Factorio 2.0 can use 1.x mods) (fixes #517)
    if [[ $(check_game_version "$mod_factorio_version" "$FACTORIO_VERSION") == 0 ]]; then
      echo "  Skipping mod version $mod_version because of factorio version mismatch"  >&2
      continue
    fi

    # If we found 'dependencies' element, we also check versions there
    if [[ $(echo "$mod_release_info" | jq -e '.info_json | has("dependencies") and (.dependencies | length > 0)') == true ]]; then
      while IFS= read -r dependency; do

        # We only check for 'base' dependency
        if [[ "$dependency" == base* ]] && [[ $(check_dependency_version "$dependency" "$FACTORIO_VERSION") == 0 ]]; then
          echo "  Skipping mod version $mod_version, unsatisfied base dependency: $dependency" >&2
          continue 2
        fi

      done < <(echo "$mod_release_info" | jq -r '.info_json.dependencies[]')
    fi

    echo "$mod_release_info" | jq -j ".file_name, \";\", .download_url, \";\", .sha1"
    break

  done < <(echo "$mod_info_json" | jq -c ".releases|sort_by(.released_at)|reverse|.[]")
}

# Check if a mod should be ignored based on UPDATE_IGNORE environment variable
is_mod_ignored() {
  local mod_name="$1"
  
  # If UPDATE_IGNORE is not set or empty, don't ignore any mods
  if [[ -z "${UPDATE_IGNORE:-}" ]]; then
    return 1
  fi
  
  # Split the comma-separated list and check if mod_name is in it
  IFS=',' read -ra ignored_mods <<< "$UPDATE_IGNORE"
  for ignored_mod in "${ignored_mods[@]}"; do
    # Trim whitespace from ignored_mod
    ignored_mod=$(echo "$ignored_mod" | xargs)
    if [[ "$mod_name" == "$ignored_mod" ]]; then
      return 0
    fi
  done
  
  return 1
}

update_mod()
{
  MOD_NAME="$1"
  MOD_NAME_ENCODED="${1// /%20}"

  print_step "Checking for update of mod $MOD_NAME for factorio $FACTORIO_VERSION ..."

  MOD_INFO_URL="$MOD_BASE_URL/api/mods/$MOD_NAME_ENCODED/full"
  MOD_INFO_JSON=$(curl --silent "$MOD_INFO_URL")

  if ! echo "$MOD_INFO_JSON" | jq -e .name >/dev/null; then
    print_success "  Custom mod not on $MOD_BASE_URL, skipped."
    return 0
  fi

  MOD_INFO=$(get_mod_info "$MOD_INFO_JSON")

  if [[ "$MOD_INFO" == "" ]]; then
    print_failure "  Not compatible with version"
    return 0
  fi

  MOD_FILENAME=$(echo "$MOD_INFO" | cut -f1 -d";")
  MOD_URL=$(echo "$MOD_INFO" | cut -f2 -d";")
  MOD_SHA1=$(echo "$MOD_INFO" | cut -f3 -d";")

  if [[ $MOD_FILENAME == null ]]; then
    print_failure "  Not compatible with version"
    return 0
  fi

  if [[ -f $MOD_DIR/$MOD_FILENAME ]]; then
    print_success "  Already up-to-date."
    return 0
  fi

  print_step "  Downloading $MOD_FILENAME"
  FULL_URL="$MOD_BASE_URL$MOD_URL?username=$USERNAME&token=$TOKEN"
  HTTP_STATUS=$(curl --silent -L -w "%{http_code}" -o "$MOD_DIR/$MOD_FILENAME" "$FULL_URL")

  if [[ $HTTP_STATUS != 200 ]]; then
    print_failure "  Download failed: Code $HTTP_STATUS."
    rm -f "$MOD_DIR/$MOD_FILENAME"
    return 1
  fi

  if [[ ! -f $MOD_DIR/$MOD_FILENAME ]]; then
    print_failure "  Downloaded file missing!"
    return 1
  fi

  if ! [[ $(sha1sum "$MOD_DIR/$MOD_FILENAME") =~ $MOD_SHA1 ]]; then
    print_failure "  SHA1 mismatch!"
    rm -f "$MOD_DIR/$MOD_FILENAME"
    return 1
  fi

  print_success "  Download complete."

  for file in "$MOD_DIR/${MOD_NAME}_"*".zip"; do # wildcard does usually not work in quotes: https://unix.stackexchange.com/a/67761
    if [[ $file != $MOD_DIR/$MOD_FILENAME ]]; then
      print_success "  Deleting old version: $file"
      rm -f "$file"
    fi
  done

  return 0
}

# Process all enabled mods from mod-list.json, but skip built-in mods
# The Space Age DLC includes built-in mods (elevated-rails, quality, space-age) that should not be downloaded
if [[ -f $MOD_DIR/mod-list.json ]]; then
  jq -r ".mods|map(select(.enabled))|.[].name" "$MOD_DIR/mod-list.json" | while read -r mod; do
    # Skip base mod and DLC built-in mods
    if [[ $mod != base ]] && [[ $mod != elevated-rails ]] && [[ $mod != quality ]] && [[ $mod != space-age ]]; then
      if is_mod_ignored "$mod"; then
        print_success "Skipping mod $mod (listed in UPDATE_IGNORE)"
      else
        update_mod "$mod" || true
      fi
    fi
  done
fi
