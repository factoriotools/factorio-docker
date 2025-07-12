# Rootless Docker Support

This document describes the rootless Docker images for Factorio, which are designed to work better with rootless Docker installations and avoid permission issues.

## What is Rootless Docker?

Rootless Docker allows running the Docker daemon and containers as a non-root user, which improves security by eliminating the need for root privileges. However, it introduces complexity with UID/GID mapping that can cause permission issues with volumes.

## Rootless Image Tags

For each regular Factorio image tag, there's a corresponding rootless tag with the `-rootless` suffix:

- `latest` → `latest-rootless`
- `stable` → `stable-rootless`
- `2.0.55` → `2.0.55-rootless`
- etc.

## Key Differences from Regular Images

1. **No dynamic UID/GID mapping**: The rootless images run as UID 1000 by default and don't support PUID/PGID environment variables
2. **No runtime chown operations**: Eliminates the recursive chown that can cause race conditions
3. **Simplified permissions**: All directories are created with open permissions (777) during build
4. **USER directive**: The container runs as non-root from the start

## Usage

### Basic Usage

```bash
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  factoriotools/factorio:stable-rootless
```

### With Rootless Docker

If you're running rootless Docker, the container will work out of the box:

```bash
# As your regular user (not root)
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v ~/factorio:/factorio \
  --name factorio \
  factoriotools/factorio:stable-rootless
```

### With Regular Docker

If you're running regular Docker but want to avoid permission issues:

```bash
# Pre-create the volume directory with your user's permissions
mkdir -p /opt/factorio
sudo chown -R $(id -u):$(id -g) /opt/factorio

# Run the container
docker run -d \
  --user $(id -u):$(id -g) \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  factoriotools/factorio:stable-rootless
```

## Environment Variables

All the same environment variables from the regular image are supported, except:
- `PUID` - Not supported (container runs as UID 1000)
- `PGID` - Not supported (container runs as GID 1000)

## Migrating from Regular Images

If you're switching from a regular image to a rootless image:

1. Stop your existing container
2. Fix permissions on your volume (one time only):
   ```bash
   sudo chown -R 1000:1000 /opt/factorio
   # Or if you want to match your user:
   sudo chown -R $(id -u):$(id -g) /opt/factorio
   ```
3. Start the new rootless container

## Troubleshooting

### Permission Denied Errors

If you get permission errors, ensure your volume directory is writable by UID 1000 or your user:

```bash
# Check current ownership
ls -la /opt/factorio

# Fix ownership for UID 1000 (default)
sudo chown -R 1000:1000 /opt/factorio

# Or fix for your current user
sudo chown -R $(id -u):$(id -g) /opt/factorio
```

### Running as a Different User

If you need to run as a different UID, override it at runtime:

```bash
docker run -d \
  --user 2000:2000 \
  -v /opt/factorio:/factorio \
  factoriotools/factorio:stable-rootless
```

## Building Rootless Images

To build rootless images locally:

```bash
# Build rootless images for current architecture
python3 build.py --rootless

# Build and push multi-arch rootless images
python3 build.py --rootless --multiarch --push-tags

# Build both regular and rootless images
python3 build.py --both --multiarch --push-tags
```

## Why Use Rootless Images?

1. **Avoid permission issues**: No more files with unexpected ownership
2. **Better security**: Runs as non-root by default
3. **Simpler**: No complex permission logic at startup
4. **Faster startup**: No recursive chown operations
5. **Rootless Docker compatible**: Works seamlessly with rootless Docker installations