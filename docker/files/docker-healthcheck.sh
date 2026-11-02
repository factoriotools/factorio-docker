#!/bin/bash
set -euo pipefail

# Avoid invoking the RCON client before startup has created its password file.
[[ -s "${CONFIG:?}/rconpw" && -r "$CONFIG/rconpw" ]] || exit 1

# A TCP connection alone cannot detect failed authentication or a stuck server.
response=$(timeout 5s rcon /players count) || exit 1
[[ "$response" =~ ^Players\ \([0-9]+\): ]]
