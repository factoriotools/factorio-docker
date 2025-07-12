#!/usr/bin/env python3
"""
Legacy wrapper script for backwards compatibility.
This script now calls build-unified.py to build regular images.
"""

import subprocess
import sys

# Convert arguments and pass to unified script
args = ["./build-unified.py"]
args.extend(sys.argv[1:])

# Execute the unified build script
sys.exit(subprocess.call(args))