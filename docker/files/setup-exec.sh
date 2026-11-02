#!/bin/bash
# Setup EXEC variable for running Factorio with ARM64 emulation support
# This script handles ARM64 emulation and can be combined with user switching as needed

# If EXEC is not already set, initialize it
if [[ -z "${EXEC:-}" ]]; then
  EXEC=""
fi

if [[ -f /bin/box64 ]]; then
  # Use an emulator to run on ARM hosts
  # this only gets installed when the target docker platform is linux/arm64
  EXEC="$EXEC /bin/box64"
fi

export EXEC