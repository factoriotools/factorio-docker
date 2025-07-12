# Factorio Docker Permission Issues - Solutions and Workarounds

This document provides comprehensive solutions and workarounds for permission-related issues in the Factorio Docker container, based on detailed analysis of issues #558, #556, #555, #549, #496, #501, #492, and #420.

## Table of Contents
- [Root Cause Analysis](#root-cause-analysis)
- [Critical Prerequisites](#critical-prerequisites)
- [General Solutions](#general-solutions)
- [Platform-Specific Issues](#platform-specific-issues)
- [Docker System Requirements](#docker-system-requirements)
- [Advanced Troubleshooting](#advanced-troubleshooting)
- [Known Issues and Limitations](#known-issues-and-limitations)

## Root Cause Analysis

Based on detailed investigation by maintainer @Fank and community reports, the permission issues stem from:

1. **Container Architecture Issues**:
   - No `USER` directive in Dockerfile despite creating a factorio user
   - Container starts as root and performs recursive `chown` on every start
   - The recursive `chown -R factorio:factorio /factorio` can be interrupted, leaving inconsistent permissions
   - Dynamic UID/GID mapping using PUID/PGID environment variables adds complexity

2. **Rootless Docker Complications**:
   - UID namespace remapping (e.g., container UID 845 → host UID 100844)
   - Rootless Docker daemons cannot change ownership of bind-mounted volumes
   - Different rootless implementations use different UID mappings

3. **Host System Dependencies**:
   - Older Docker versions (especially pre-20.x) have permission handling bugs
   - Some kernel versions have issues with user namespace operations
   - SELinux and AppArmor can interfere with volume permissions

## Critical Prerequisites

### Update Your System First!
Many permission issues are caused by outdated system components:

```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get upgrade

# Specifically update Docker to 27.x or newer
# Follow: https://docs.docker.com/engine/install/ubuntu/#install-docker-engine
```

**Important**: Multiple users reported that updating Docker resolved their "Operation not permitted" errors.

## General Solutions

### Solution A: Pre-create Directories with Correct Permissions
```bash
# Create the directory structure
sudo mkdir -p /opt/factorio/{saves,mods,config,scenarios,script-output}

# Set ownership to factorio user (845:845)
sudo chown -R 845:845 /opt/factorio

# Set appropriate permissions (note the 'u+rwx' for write access)
sudo chmod -R u+rwx /opt/factorio
```

### Solution B: Use the Rootless Docker Image (Recommended)
The project now provides a rootless variant that runs as UID 1000, which avoids most permission issues:
```bash
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  factoriotools/factorio:latest-rootless
```

**Benefits of rootless images**:
- No `chown` operations on startup
- No need to pre-create directories with specific permissions
- Works seamlessly with rootless Docker installations
- Avoids the recursive permission changes that can be interrupted

**Available rootless tags**:
- `latest-rootless`
- `stable-rootless`
- `2.0.55-rootless` (or any specific version with `-rootless` suffix)

## Platform-Specific Issues and Solutions

### NixOS with Rootless Docker

**Problem**: Permission denied errors when creating directories, even after setting ownership to 845:845. Files show ownership by UID 100844 instead of 845.

**Solutions**:
1. **Find and use your actual rootless Docker user ID**:
   ```bash
   # Method 1: Check your user ID
   id -u
   
   # Method 2: Check existing Docker volumes for the UID Docker is using
   ls -lan /path/to/other/docker/volumes
   
   # Common rootless Docker UIDs:
   # - 100999 (NixOS default)
   # - 100844 (as reported in issue #558)
   # - 1000 (some configurations)
   
   # Apply the correct ownership
   sudo chown -R 100999:100999 ./factorio
   ```

2. **Configure NixOS Docker properly**:
   ```nix
   # In configuration.nix
   virtualisation.docker.rootless = {
     enable = true;
     setSocketVariable = true;
   };
   ```

3. **Port Mapping Issues**: Rootless Docker on NixOS has issues with userland-proxy that can cause random port assignments. Consider using host networking if possible.

### macOS with Colima

**Problem**: `copy_file` permission denied errors, even with correct ownership. Permission errors when running docker-dlc.sh.

**Solutions**:
1. **Set broader permissions before mounting**:
   ```bash
   # Create directory structure
   mkdir -p ./factorio-server/{saves,mods,config,scenarios}
   
   # Set ownership AND permissions
   sudo chown -R 845:845 ./factorio-server
   sudo chmod -R 775 ./factorio-server
   ```

2. **Use Docker Desktop instead of Colima** if the issues persist, as it has better macOS integration

3. **Specify PUID/PGID explicitly**:
   ```yaml
   environment:
     - PUID=502  # Common macOS user ID
     - PGID=20   # Common macOS staff group
   ```

### Windows

**Problem**: Cannot remove temporary locale files due to Windows-Linux permission translation. Errors like "Permission denied trying to remove /factorio/temp/currently-playing/locale/de".

**Solutions**:
1. **Use WSL2 backend** for Docker Desktop (required for proper Linux filesystem semantics)

2. **Store volumes in WSL2 filesystem** instead of Windows filesystem:
   ```bash
   # Inside WSL2 terminal
   mkdir -p ~/factorio
   chmod -R 777 ~/factorio
   ```
   
   ```yaml
   # docker-compose.yml - use WSL2 path
   volumes:
     - ~/factorio:/factorio
   ```

3. **Avoid Windows drive mounts** (like `W:\docker\factorio`) as they have inherent permission translation issues

4. **Add :Z flag for SELinux context** (some Windows Docker setups benefit from this):
   ```yaml
   volumes:
     - ~/factorio:/factorio:Z
   ```

### Synology NAS

**Problem**: Permission denied when accessing mounted volumes. Error: "filesystem error: status: Permission denied [/factorio/saves]".

**Solutions**:
1. **Create and set permissions via SSH**:
   ```bash
   # SSH into Synology
   sudo mkdir -p /volume1/docker/factorio
   sudo chown -R 845:845 /volume1/docker/factorio
   sudo chmod -R u+rwx /volume1/docker/factorio  # Important: u+rwx for write access
   ```

2. **Use the correct volume path in your container**:
   ```bash
   docker run -d \
     -p 34197:34197/udp \
     -p 27015:27015/tcp \
     -v /volume1/docker/factorio:/factorio \
     --name factorio \
     --restart=always \
     factoriotools/factorio
   ```

3. **Check DSM Docker permissions** - ensure the Docker package has proper permissions to the shared folder

## Docker System Requirements

### Minimum Docker Version
Based on community reports, these Docker versions are known to work:
- **Docker 27.4.1** - Confirmed working
- **Docker 20.x+** - Generally stable
- **Docker 19.x and below** - Known permission issues

**Check your Docker version**:
```bash
docker --version
# If below 20.x, update immediately!
```

### "Operation not permitted" at Util.cpp:81
This specific error is often caused by:
1. **Outdated Docker version** - Update Docker first!
2. **Outdated kernel** - Run system updates
3. **Missing kernel capabilities** - Check Docker daemon configuration

## Docker Compose Best Practices

### Basic Configuration
```yaml
version: '3'
services:
  factorio:
    image: factoriotools/factorio:stable
    container_name: factorio
    ports:
      - "34197:34197/udp"
      - "27015:27015/tcp"
    volumes:
      - ./factorio:/factorio
    restart: unless-stopped
    stdin_open: true  # For interactive console
    tty: true
```

### Advanced Configuration for Permission Issues
```yaml
version: '3'
services:
  factorio:
    image: factoriotools/factorio:stable
    container_name: factorio
    ports:
      - "34197:34197/udp"
      - "27015:27015/tcp"
    volumes:
      - ./factorio:/factorio:Z  # :Z for SELinux systems
    restart: unless-stopped
    # user: "845:845"  # WARNING: This might break the entrypoint script
    environment:
      - PUID=845
      - PGID=845
      - UPDATE_MODS_ON_START=false  # Disable if having permission issues
```

### Rootless Docker Configuration
```yaml
version: '3'
services:
  factorio:
    image: factoriotools/factorio:latest-rootless
    container_name: factorio
    ports:
      - "34197:34197/udp"
      - "27015:27015/tcp"
    volumes:
      - ./factorio:/factorio
    restart: unless-stopped
    environment:
      - PUID=1000  # Rootless default
      - PGID=1000
```

## Advanced Troubleshooting

### Step-by-Step Diagnosis

1. **Check Current Ownership**:
   ```bash
   ls -lan ./factorio
   # Look for UIDs like 845, 1000, 100844, 100999
   ```

2. **Verify Docker User Mapping**:
   ```bash
   # Check what user the container is running as
   docker exec factorio id
   
   # Check file ownership inside container
   docker exec factorio ls -lan /factorio
   ```

3. **Test Without Volume Mount** (isolates host permission issues):
   ```bash
   docker run --rm -it factoriotools/factorio:stable
   # If this works, the issue is with your host volume permissions
   ```

4. **Check Security Modules**:
   ```bash
   # SELinux (Fedora, RHEL, CentOS)
   getenforce
   # If "Enforcing", try adding :Z to volume mount
   
   # AppArmor (Ubuntu, Debian)
   sudo apparmor_status | grep docker
   ```

5. **Debug the Entrypoint Script**:
   ```bash
   # Run with debug output
   docker run --rm -it \
     -e DEBUG=true \
     -v ./factorio:/factorio \
     factoriotools/factorio:stable
   ```

### Common Error Messages and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Util.cpp:81: Operation not permitted` | Outdated Docker/kernel | Update Docker and system packages |
| `chown: Operation not permitted` | Rootless Docker | Use rootless Docker UID for ownership |
| `Permission denied [/factorio/saves]` | Wrong directory permissions | `chmod -R u+rwx` on host directory |
| `Couldn't create lock file /factorio/.lock` | Container can't write to volume | Check volume mount and permissions |
| `Map version X cannot be loaded` | Version mismatch | Use correct Docker image version |

## Known Issues and Limitations

### Interrupted chown Operations
The container performs `chown -R factorio:factorio /factorio` on every start. If the container is killed during this operation:
- Files will have inconsistent ownership
- Some files owned by 845, others by different UIDs
- Solution: Let the container complete startup before stopping

### Rootless Docker Port Mapping
**Issue #496**: Rootless Docker with userland-proxy causes random port assignments instead of the configured 34197.
- **Workaround**: Use host networking mode if possible
- **Note**: This is a Docker limitation, not specific to this image

### Map Version Compatibility
**Problem**: "Map version 2.0.23-0 cannot be loaded because it is higher than the game version".

**Solution**: 
```bash
# Use a version that matches or exceeds your save
docker pull factoriotools/factorio:2.0.23
# Or always use latest for newest features
docker pull factoriotools/factorio:latest
```

## Recommended Approach

### For New Installations
1. **Update your system first** - Many issues are caused by old Docker versions
2. **Try the rootless image first** - It avoids most permission issues entirely
3. **Pre-create directories** with correct permissions if using the standard image
4. **Test without volumes** first to ensure the image works

### For Existing Installations with Issues
1. **Stop the container** and let it shut down cleanly
2. **Backup your data** before making changes
3. **Check Docker version** - update if below 20.x
4. **Fix permissions** using the platform-specific solution
5. **Consider rootless variant** for easier permission management

### Best Practices
- **Let the container start fully** before stopping (avoid interrupted chown)
- **Use named volumes** instead of bind mounts when possible
- **Monitor first startup** to ensure permissions are set correctly
- **Keep Docker updated** to avoid known bugs

## Community Solutions

### Proposed Improvements (from @Fank)
1. **Add USER directive** in Dockerfile after creating directories
2. **Optimize chown logic** to only run when ownership is wrong
3. **Implement fixuid** for better UID/GID mapping
4. **Add health checks** to ensure permissions are correct before starting

### Alternative Images
Some users have tried other Factorio Docker images (e.g., goofball222/factorio) but report the same Util.cpp:81 errors, suggesting this is a broader ecosystem issue related to Docker versions and system configurations.

## Quick Reference

| Platform | Common UID | Recommended Approach |
|----------|-----------|---------------------|
| Standard Docker | 845 | Update Docker, use `chown 845:845` |
| Rootless Docker (NixOS) | 100999, 100844 | Find actual UID, chown to that |
| macOS (Docker Desktop) | 502 (user), 20 (staff) | Use PUID/PGID env vars |
| Windows | N/A | Use WSL2 filesystem |
| Synology NAS | varies | Check DSM user, ensure Docker has folder access |

## Getting Help

If these solutions don't work:
1. **Update everything first** (Docker, kernel, system packages)
2. **Provide full details** when reporting issues:
   - Docker version (`docker --version`)
   - OS and version
   - Full error messages
   - Output of `ls -lan` on your volume
3. **Try the rootless image** as an alternative
4. **Check issue #558** for ongoing discussions

Remember: The vast majority of permission issues are resolved by updating Docker to version 20.x or newer!