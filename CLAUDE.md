# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker image for running a Factorio headless server. It provides automated builds for multiple Factorio versions (stable and experimental) and supports both AMD64 and ARM64 architectures.

## Architecture

### Key Components

1. **Docker Image Build System**
   - `build.py` - Unified Python script that builds both regular and rootless Docker images from `buildinfo.json`
   - `docker/Dockerfile` - Main Dockerfile that creates the Factorio server image
   - `docker/Dockerfile.rootless` - Dockerfile for rootless variant (runs as UID 1000)
   - `buildinfo.json` - Contains version info, SHA256 checksums, and tags for all supported versions
   - Supports multi-architecture builds (linux/amd64, linux/arm64) using Docker buildx

2. **Automated Updates**
   - `update.sh` - Checks for new Factorio releases and updates `buildinfo.json`
   - Updates README.md with new version tags
   - Commits changes and tags releases automatically
   - Run by GitHub Actions to keep images up-to-date

3. **Container Scripts**
   - `docker/files/docker-entrypoint.sh` - Main entrypoint that configures and starts the server
   - `docker/files/docker-update-mods.sh` - Updates mods on server start
   - `docker/files/docker-dlc.sh` - Manages DLC (Space Age) activation
   - `docker/files/scenario.sh` - Alternative entrypoint for launching scenarios
   - `docker/files/players-online.sh` - Checks if players are online (for watchtower integration)

4. **RCON Client**
   - `docker/rcon/` - C source for RCON client, built during Docker image creation
   - Allows sending commands to the running server

## Common Development Commands

### Building Images

```bash
# Build regular images locally (single architecture)
python3 build.py

# Build rootless images only
python3 build.py --rootless

# Build both regular and rootless images
python3 build.py --both

# Build and push multi-architecture images (regular only)
python3 build.py --multiarch --push-tags

# Build and push both regular and rootless multi-architecture images
python3 build.py --multiarch --push-tags --both
```

### Running the Container

```bash
# Basic run command
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  factoriotools/factorio

# Using docker-compose
docker-compose up -d
```

### Linting

```bash
# Lint Dockerfiles
./lint.sh
```

### Testing Updates

```bash
# Check for new Factorio versions and update buildinfo.json
./update.sh
```

## Key Configuration

### Environment Variables
- `LOAD_LATEST_SAVE` - Load the most recent save (default: true)
- `GENERATE_NEW_SAVE` - Generate a new save if none exists (default: false)
- `SAVE_NAME` - Name of the save file to load/create
- `UPDATE_MODS_ON_START` - Update mods before starting (requires USERNAME/TOKEN)
- `DLC_SPACE_AGE` - Enable/disable Space Age DLC (default: true)
- `PORT` - UDP port for game server (default: 34197)
- `RCON_PORT` - TCP port for RCON (default: 27015)

### Volume Structure
All data is stored in a single volume mounted at `/factorio`:
```
/factorio/
├── config/           # Server configuration files
├── mods/            # Game modifications
├── saves/           # Save games
├── scenarios/       # Scenario files
└── script-output/   # Script output directory
```

## Version Management

The project maintains compatibility with multiple Factorio versions:
- Latest experimental version gets the `latest` tag
- Latest stable version gets the `stable` tag
- Each version also gets specific tags (e.g., `2.0.55`, `2.0`, `2`)
- Legacy versions back to 0.12 are supported

Version updates are automated via GitHub Actions that run `update.sh` periodically.

## Testing Changes

1. Modify `buildinfo.json` to test specific versions
2. Run `python3 build.py` to build regular images locally
   - Use `python3 build.py --rootless` for rootless images
   - Use `python3 build.py --both` to build both variants
3. Test the container with your local data volume
4. For production changes, ensure `update.sh` handles version transitions correctly