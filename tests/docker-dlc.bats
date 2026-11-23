#!/usr/bin/env bats

setup() {
  export MODS="$BATS_TEST_TMPDIR"
  MOD_LIST="$MODS/mod-list.json"
}

write_mod_list() {
  printf '%s\n' "$1" > "$MOD_LIST"
}

# Mixed state: two DLC mods on, two off, plus a non-DLC mod.
write_mixed_mod_list() {
  write_mod_list '{"mods":[
    {"name":"base","enabled":true},
    {"name":"elevated-rails","enabled":false},
    {"name":"quality","enabled":true},
    {"name":"space-age","enabled":false},
    {"name":"recycler","enabled":true},
    {"name":"quality-of-life","enabled":true}
  ]}'
}

run_dlc() {
  DLC_SPACE_AGE="$1" run bash "$BATS_TEST_DIRNAME/../docker/files/docker-dlc.sh"
  [ "$status" -eq 0 ]
}

mod_states() {
  jq -r '.mods[] | "\(.name)=\(.enabled)"' "$MOD_LIST"
}

@test "true enables every DLC mod and leaves other mods alone" {
  write_mixed_mod_list
  run_dlc true
  [ "$(mod_states)" = "base=true
elevated-rails=true
quality=true
space-age=true
recycler=true
quality-of-life=true" ]
}

@test "false disables every DLC mod and leaves other mods alone" {
  write_mixed_mod_list
  run_dlc false
  [ "$(mod_states)" = "base=true
elevated-rails=false
quality=false
space-age=false
recycler=false
quality-of-life=true" ]
}

@test "a single mod name enables only that DLC mod" {
  write_mixed_mod_list
  run_dlc elevated-rails
  [ "$(mod_states)" = "base=true
elevated-rails=true
quality=false
space-age=false
recycler=false
quality-of-life=true" ]
}

@test "a space-separated list enables exactly the listed DLC mods" {
  write_mixed_mod_list
  run_dlc "quality space-age"
  [ "$(mod_states)" = "base=true
elevated-rails=false
quality=true
space-age=true
recycler=false
quality-of-life=true" ]
}

@test "names only match whole words" {
  write_mixed_mod_list
  run_dlc "quality-of-life space"
  [ "$(mod_states)" = "base=true
elevated-rails=false
quality=false
space-age=false
recycler=false
quality-of-life=true" ]
}

@test "an empty value disables every DLC mod" {
  write_mixed_mod_list
  run_dlc ""
  [ "$(mod_states)" = "base=true
elevated-rails=false
quality=false
space-age=false
recycler=false
quality-of-life=true" ]
}

@test "a missing mod list is created and disabled DLC mods are added" {
  run_dlc false
  [ "$(mod_states)" = "base=true
elevated-rails=false
quality=false
space-age=false
recycler=false" ]
}

@test "enabling does not add DLC mods absent from the mod list" {
  run_dlc true
  [ "$(mod_states)" = "base=true" ]

  write_mod_list '{"mods":[{"name":"base","enabled":true},{"name":"quality","enabled":false}]}'
  run_dlc "quality space-age"
  [ "$(mod_states)" = "base=true
quality=true
elevated-rails=false
recycler=false" ]
}

@test "running twice gives the same result" {
  write_mixed_mod_list
  run_dlc "elevated-rails recycler"
  local first
  first=$(mod_states)
  run_dlc "elevated-rails recycler"
  [ "$(mod_states)" = "$first" ]
  [ ! -e "$MOD_LIST.tmp" ]
}
