#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "$BATS_TEST_DIRNAME/../docker/files/update-mods.sh"
}

@test "game compatibility matches the branch, including the 1.0 exception" {
  while read -r mod game expected; do
    run check_game_version "$mod" "$game"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
  done <<'CASES'
2.0 2.0.77 1
1.1 2.0.77 0
2.0 2.1.24 0
2.1 2.0.77 0
0.18 1.0.0 1
1.0 1.0.0 1
0.17 1.0.0 0
0.18 1.1.110 0
0.12 0.12.35 1
CASES
}

@test "release selection skips wrong branches and unmet base patch requirements" {
  export FACTORIO_VERSION=2.0.77
  run --separate-stderr get_mod_info '{"releases":[
    {"version":"1.0.0","released_at":"2025-01-01","info_json":{"factorio_version":"2.0"},"file_name":"old.zip","download_url":"/old","sha1":"old"},
    {"version":"2.0.0","released_at":"2025-01-02","info_json":{"factorio_version":"2.0","dependencies":["base >= 2.0.77"]},"file_name":"selected.zip","download_url":"/selected","sha1":"selected"},
    {"version":"3.0.0","released_at":"2025-01-03","info_json":{"factorio_version":"2.0","dependencies":["base >= 2.0.78"]}},
    {"version":"4.0.0","released_at":"2025-01-04","info_json":{"factorio_version":"1.1"}},
    {"version":"5.0.0","released_at":"2025-01-05","info_json":{"factorio_version":"2.1"}}
  ]}'
  [ "$status" -eq 0 ]
  [ "$output" = 'selected.zip;/selected;selected' ]
}

@test "missing factorio_version defaults to 0.12, not a modern branch" {
  local releases='{"releases":[{"version":"1.0.0","released_at":"2015-01-01","info_json":{},"file_name":"legacy.zip","download_url":"/legacy","sha1":"legacy"}]}'
  export FACTORIO_VERSION=0.12.35
  run --separate-stderr get_mod_info "$releases"
  [ "$status" -eq 0 ]
  [ "$output" = 'legacy.zip;/legacy;legacy' ]

  export FACTORIO_VERSION=2.0.77
  run --separate-stderr get_mod_info "$releases"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "sourcing without arguments preserves shell options and does not run updates" {
  run bash -c '
    script=$1
    set --
    before=$(set +o)
    source "$script"
    [[ $(set +o) == "$before" ]]
  ' bash "$BATS_TEST_DIRNAME/../docker/files/update-mods.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "executing the updater still processes enabled mods" {
  printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"example","enabled":true}]}' > "$BATS_TEST_TMPDIR/mod-list.json"
  run bash "$BATS_TEST_DIRNAME/../docker/files/update-mods.sh" 2.0.77 "$BATS_TEST_TMPDIR" unused unused example
  [ "$status" -eq 0 ]
  [ "$output" = 'Skipping mod example (listed in UPDATE_IGNORE)' ]
}
