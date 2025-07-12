#!/usr/bin/env python3
"""
Legacy wrapper script for backwards compatibility.
This script now calls build-unified.py to build rootless images.
"""

import subprocess
import sys

# Convert arguments and pass to unified script with --rootless flag
args = ["./build-unified.py", "--rootless", "--only-stable-latest"]
args.extend(sys.argv[1:])

# Execute the unified build script
sys.exit(subprocess.call(args))