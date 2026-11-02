#!/bin/bash

PLAYERS=$(rcon /players)
ONLINE_COUNT=$(echo "$PLAYERS" | grep -c " (online)$")

if [[ "$ONLINE_COUNT" -gt "0" ]]; then
    echo "$PLAYERS"
    # exit with 75 (EX_TEMPFAIL) so watchtower skips the update
    # https://containrrr.dev/watchtower/lifecycle-hooks/
    exit 75
fi
