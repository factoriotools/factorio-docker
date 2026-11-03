#!/usr/bin/env bats

setup() {
  export CONFIG="$BATS_TEST_TMPDIR/config" SAVES="$BATS_TEST_TMPDIR/saves"
  export MODS="$BATS_TEST_TMPDIR/mods" SCENARIOS="$BATS_TEST_TMPDIR/scenarios"
  export SCRIPTOUTPUT="$BATS_TEST_TMPDIR/output" PORT=34197 RCON_PORT=27015
  export LOAD_LATEST_SAVE=true GENERATE_NEW_SAVE=false UPDATE_MODS_ON_START=false
  export ARGS_FILE="$BATS_TEST_TMPDIR/args"
  local scripts="$BATS_TEST_TMPDIR/scripts" opt="$BATS_TEST_TMPDIR/opt"
  mkdir -p "$scripts" "$opt/bin/x64" "$opt/config" "$CONFIG" "$SAVES"
  export PATH="$scripts:$PATH"
  unset SERVER_SETTINGS_FILE SERVER_ID_FILE SERVER_ADMINLIST_FILE SERVER_BANLIST_FILE SERVER_WHITELIST_FILE BASH_ENV
  local script
  for script in docker-entrypoint.sh docker-entrypoint-rootless.sh scenario.sh server-config.sh; do
    sed -e "s|/opt/factorio|$opt|g" -e "s|FACTORIO_VOL=/factorio|FACTORIO_VOL=$BATS_TEST_TMPDIR/volume|g" \
      "$BATS_TEST_DIRNAME/../docker/files/$script" > "$scripts/$script"
  done
  printf '#!/bin/sh\nprintf "1000\\n"\n' > "$scripts/id"
  printf '#!/bin/sh\nexit 0\n' > "$scripts/docker-dlc.sh"
  printf ':\n' > "$scripts/setup-exec.sh"
  printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "$ARGS_FILE"\n' > "$opt/bin/x64/factorio"
  chmod +x "$scripts/id" "$scripts/docker-dlc.sh" "$opt/bin/x64/factorio"
  printf 'test-password\n' > "$CONFIG/rconpw"
  for script in server-settings map-gen-settings map-settings; do
    printf '{}\n' > "$CONFIG/$script.json"
  done
  touch "$SAVES/existing.zip" "$opt/config/config.ini"
}

check_startup_flags() {
  local script
  for script in docker-entrypoint.sh docker-entrypoint-rootless.sh scenario.sh; do
    run bash "$BATS_TEST_TMPDIR/scripts/$script" freeplay
    [ "$status" -eq 0 ]
    grep -Fxq -- '--server-whitelist' "$ARGS_FILE"
    grep -Fxq -- "$CONFIG/server-whitelist.json" "$ARGS_FILE"
    if [[ "$VERSION" == 0.16.* ]]; then
      run grep -Fx -- '--use-server-whitelist' "$ARGS_FILE"
      [ "$status" -eq 1 ]
      run grep -Fx -- '--server-adminlist' "$ARGS_FILE"
      [ "$status" -eq 1 ]
    else
      grep -Fxq -- '--use-server-whitelist' "$ARGS_FILE"
      grep -Fxq -- '--server-adminlist' "$ARGS_FILE"
      grep -Fxq -- "$CONFIG/server-adminlist.json" "$ARGS_FILE"
    fi
  done
}

@test "0.16 entrypoints omit unsupported flags but retain the whitelist path" {
  export VERSION=0.16.51
  check_startup_flags
}

@test "0.17 entrypoints retain whitelist enablement and the admin list" {
  export VERSION=0.17.79
  check_startup_flags
}

@test "current entrypoints retain whitelist enablement and the admin list" {
  export VERSION=2.1.24
  check_startup_flags
}
