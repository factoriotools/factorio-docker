# Build System Migration Guide

## Overview

The build system has been unified into a single script (`build-unified.py`) that can build both regular and rootless Docker images. This replaces the separate `build.py` and `build-rootless.py` scripts.

## New Unified Build Script

### Usage

```bash
# Build only regular images (default behavior)
./build-unified.py

# Build only rootless images
./build-unified.py --rootless

# Build both regular and rootless images
./build-unified.py --both

# Build with multi-architecture support
./build-unified.py --multiarch --both

# Build and push to Docker Hub
./build-unified.py --push-tags --multiarch --both

# Build only stable/latest versions (useful for rootless)
./build-unified.py --rootless --only-stable-latest --push-tags --multiarch
```

### Options

- `--push-tags`: Push images to Docker Hub (requires DOCKER_USERNAME and DOCKER_PASSWORD env vars)
- `--multiarch`: Build multi-architecture images (linux/amd64 and linux/arm64)
- `--rootless`: Build only rootless images
- `--both`: Build both regular and rootless images
- `--only-stable-latest`: Build only versions tagged as 'stable' or 'latest'

## Migration Path

### For CI/CD

The GitHub Actions workflow has been updated to use:
```yaml
./build-unified.py --push-tags --multiarch --both
```

### For Local Development

Replace old commands with new ones:

| Old Command | New Command |
|-------------|-------------|
| `./build.py` | `./build-unified.py` |
| `./build.py --multiarch` | `./build-unified.py --multiarch` |
| `./build-rootless.py` | `./build-unified.py --rootless` |
| `./build.py && ./build-rootless.py` | `./build-unified.py --both` |

## Backwards Compatibility

The original `build.py` and `build-rootless.py` scripts are now wrappers that call the unified script with appropriate arguments to maintain backwards compatibility.