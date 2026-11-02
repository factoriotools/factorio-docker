# Factorio [![Docker Version](https://img.shields.io/docker/v/factoriotools/factorio?sort=semver)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Pulls](https://img.shields.io/docker/pulls/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Stars](https://img.shields.io/docker/stars/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/)

> [!NOTE]
> ARM64 images for Factorio 2.1 and newer run the native `linux-arm64` headless build. Older versions have no native build and run the x64 build under box64 emulation, which is experimental: expect crashes and lag if you try to run those on a raspberry pi.

[中文](./README_zh_CN.md)

<!-- start autogeneration tags -->
* `latest, 2.1.24`
<!-- end autogeneration tags -->

## Tag descriptions

* `latest` - most up-to-date version (may be experimental).
* `stable` - version declared stable on [factorio.com](https://www.factorio.com) ([FFF-435 Since 2.0 versions gets released as experimental first, once stable it will be marked as stable](https://factorio.com/blog/post/fff-435)).
* `stable-x.y.z` - a specific stable release; constrain update tools to this prefix to exclude experimental releases. Rootless equivalents end in `-rootless`.
* `0.x`    - latest version in a branch.
* `0.x.y` - a specific version.
* `0.x-z` - incremental fix for that version.

## What is Factorio?

[Factorio](https://www.factorio.com) is a game in which you build and maintain factories.

You will be mining resources, researching technologies, building infrastructure, automating production and fighting enemies. Use your imagination to design your factory, combine simple elements into ingenious structures, apply management skills to keep it working and finally protect it from the creatures who don't really like you.

The game is very stable and optimized for building massive factories. You can create your own maps, write mods in Lua or play with friends via Multiplayer.

NOTE: This is only the server. The full game is available at [Factorio.com](https://www.factorio.com), [Steam](https://store.steampowered.com/app/427520/), [GOG.com](https://www.gog.com/game/factorio) and [Humble Bundle](https://www.humblebundle.com/store/factorio).

## Usage

### Quick Start

Run the server to create the necessary folder structure and configuration files. For this example data is stored in `/opt/factorio`.

```shell
sudo mkdir -p /opt/factorio
sudo chown 845:845 /opt/factorio
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=unless-stopped \
  factoriotools/factorio
```

For those new to Docker, here is an explanation of the options:

* `-d` - Run as a daemon ("detached").
* `-p` - Expose ports.
* `-v` - Mount `/opt/factorio` on the local file system to `/factorio` in the container.
* `--restart` - Restart the server if it crashes and at system start
* `--name` - Name the container "factorio" (otherwise it has a funny random name).

The `chown` command is needed because in 0.16+, we no longer run the game server as root for security reasons, but rather as a 'factorio' user with user id 845. The host must therefore allow these files to be written by that user.

Check the logs to see what happened:

```shell
docker logs factorio
```

Stop the server:

```shell
docker stop --timeout 120 factorio
```

Allow enough time for the world to save before Docker sends SIGKILL. Increase the timeout for large saves; with Compose, configure `stop_grace_period` instead.

Now there's a `server-settings.json` file in the folder `/opt/factorio/config`. Modify this to your liking and restart the server:

```shell
docker start factorio
```

Try to connect to the server. Check the logs if it isn't working.

### Console

To issue console commands to the server, start the server in interactive mode with `-it`. Open the console with `docker attach` and then type commands.

```shell
docker run -d -it  \
      --name factorio \
      factoriotools/factorio
docker attach factorio
```

### RCON (2.0.18+)

Alternativly (e.g. for scripting) the RCON connection can be used to send commands to the running factorio server.
This does not require the RCON connection to be exposed.

```shell
docker exec factorio rcon /h
```

### Server health

Regular and rootless images check server responsiveness using the read-only `rcon /players count` command, with a five-second timeout. RCON does not need to be published, and the check does not affect achievements.

```shell
docker inspect --format '{{.State.Health.Status}}' factorio
```

The default interval is 30 seconds, with three retries and a five-minute startup grace period. For large saves or heavy mod sets, adjust Compose `healthcheck.start_period`, `interval` and `retries` to allow for loading and save pauses. Use `healthcheck.disable: true` (or `docker run --no-healthcheck`) if you intentionally disable or replace RCON.

Docker reports `starting`, `healthy` or `unhealthy`; it does not automatically restart unhealthy containers. Use this status with your monitoring tool. The check does not test external UDP connectivity or provide an HTTP endpoint. Keep the Docker API and RCON private.

### Upgrading

Before upgrading backup the save. It's easy to make a save in the client.

Ensure `-v` was used to run the server so the save is outside of the Docker container. The `docker rm` command completely destroys the container, which includes the save if it isn't stored in a data volume.

Delete the container and refresh the image:

```shell
docker stop factorio
docker rm factorio
docker pull factoriotools/factorio
```

Now run the server as before. In about a minute the new version of Factorio should be up and running, complete with saves and config!

### Saves

A new map named `_autosave1.zip` (or `SAVE_NAME` when set) is generated the first time the server is started. The `map-gen-settings.json` and `map-settings.json` files in `/opt/factorio/config` are used for the map settings. On subsequent runs the newest save is used.

To load an old save stop the server and run the command `touch oldsave.zip`. This resets the date. Then restart the server. Another option is to delete all saves except one.

To generate a new map stop the server, delete all of the saves and restart the server.

#### Specify a save directly (0.17.79-2+)

You can specify a specific save to load by configuring the server through a set of environment variables:

To load an existing save, set `SAVE_NAME` to its name in the `saves` directory, with or without `.zip`, or to an absolute file path. The same path is used for generation and subsequent starts. A missing selected save produces an error rather than loading another world:

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e LOAD_LATEST_SAVE=false \
  -e SAVE_NAME=replaceme \
  --name factorio \
  --restart=unless-stopped \
  factoriotools/factorio
```

To generate a new map set `GENERATE_NEW_SAVE=true` and specify `SAVE_NAME`:

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e LOAD_LATEST_SAVE=false \
  -e GENERATE_NEW_SAVE=true \
  -e SAVE_NAME=replaceme \
  --name factorio \
  --restart=unless-stopped \
  factoriotools/factorio
```

To generate a new map with a specific preset (e.g., death-world):

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e LOAD_LATEST_SAVE=false \
  -e GENERATE_NEW_SAVE=true \
  -e SAVE_NAME=replaceme \
  -e PRESET=death-world \
  --name factorio \
  --restart=unless-stopped \
  factoriotools/factorio
```

### Mods

Copy mods into the mods folder and restart the server.

As of 0.17 a new environment variable was added ``UPDATE_MODS_ON_START`` which if set to ``true`` will cause the mods get to updated on server start. If set a valid [Factorio Username and Token](https://www.factorio.com/profile) must be supplied or else the server will not start. They can either be set as docker secrets, environment variables, or pulled from the server-settings.json file.

To prevent specific mods from being automatically updated, you can use the ``UPDATE_IGNORE`` environment variable with a comma-separated list of mod names. For example: ``UPDATE_IGNORE=mod1,mod2,mod3`` will skip updates for those three mods. This can be useful to prevent compatibility issues when certain mods should remain at specific versions. Be warned that it can also create compatibility issues.

**Note:** When using the Space Age DLC, the built-in mods (`elevated-rails`, `quality`, and `space-age`) are automatically skipped during mod updates to prevent conflicts. These mods are included with the DLC and should not be downloaded separately.

### Scenarios

If you want to launch a scenario from a clean start (not from a saved map) you'll need to start the docker image from an alternate entrypoint. To do this, use the example entrypoint file stored in the /factorio/entrypoints directory in the volume, and launch the image with the following syntax. Note that this is the normal syntax with the addition of the --entrypoint setting AND the additional argument at the end, which is the name of the Scenario in the Scenarios folder.

```shell
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=unless-stopped  \
  --entrypoint "/scenario.sh" \
  factoriotools/factorio \
  MyScenarioName
```

### Converting Scenarios to Regular Maps (deprecated)

The legacy `/scenario2map.sh` wrapper is retained for compatibility, but is deprecated for new deployments. Factorio's `--scenario2map` operation does not apply `map-gen-settings.json` or `map-settings.json`; copying those files does not make conversion honor them. See the [upstream explanation](https://forums.factorio.com/viewtopic.php?f=23&t=69377&p=422321#p422321).

Instead, use `/scenario.sh` as described above to start a scenario with the desired map settings, then save the running world through the console or RCON (`/server-save`). After confirming the save completed, stop the container and use the normal entrypoint to load that save. Keep a backup before changing an existing world.

### RCON

Set the RCON password in the `rconpw` file. A random password is generated if `rconpw` doesn't exist.

To change the password, stop the server, modify `rconpw`, and restart the server.

To "disable" RCON don't expose port 27015, i.e. start the server without `-p 27015:27015/tcp`. RCON is still running, but nobody can to connect to it.

### Whitelisting (0.15.3+)

Create file `config/server-whitelist.json` and add the whitelisted users.

```json
[
"you",
"friend"
]
```

### Banlisting (0.17.1+)

Create file `config/server-banlist.json` and add the banlisted users.

```json
[
"bad_person",
"other_bad_person"
]
```

### Adminlisting (0.17.1+)

Create file `config/server-adminlist.json` and add the adminlisted users.

```json
[
"you",
"friend"
]
```

### Customize configuration files (0.17.x+)

Factorio does not expand environment variables inside JSON. Prefer mounting a complete settings file (see `SERVER_SETTINGS_FILE` below). If you need per-instance values from Compose, the image already includes `jq`, which safely encodes quotes, backslashes and newlines instead of doing raw text substitution.

First create a **complete, valid** `server-settings.json` template, for example by copying `data/config/server-settings.json` after the initial startup. The following example mounts that template read-only and renders a separate settings file on every start. Supplied variables override the template; unset variables preserve its values. This intentionally regenerates the output file: edit the template, not the generated copy.

<!-- start settings provisioning example -->
```yaml
services:
  factorio:
    image: factoriotools/factorio:stable
    ports:
      - "34197:34197/udp"
    volumes:
      - ./data:/factorio
      - ./server-settings.json:/server-settings.template.json:ro
    environment:
      INSTANCE_NAME: "My Factorio server"
      INSTANCE_DESC: "A server configured through Compose"
      # Optional: USERNAME, TOKEN and GAME_PASSWORD override the matching fields.
      # Keep credentials out of version control.
    entrypoint:
      - /bin/sh
      - -ec
      - |
        mkdir -p /factorio/config
        jq '
          .name = (env.INSTANCE_NAME // .name) |
          .description = (env.INSTANCE_DESC // .description) |
          .username = (env.USERNAME // .username) |
          .token = (env.TOKEN // .token) |
          .game_password = (env.GAME_PASSWORD // .game_password)
        ' /server-settings.template.json > /factorio/config/server-settings.json.tmp
        mv /factorio/config/server-settings.json.tmp /factorio/config/server-settings.json
        exec /docker-entrypoint.sh
```
<!-- end settings provisioning example -->

These settings variables are consumed by this example wrapper, not by the normal entrypoint. Set `visibility.public` explicitly in the template; public listing also needs valid Factorio credentials. For rootless images, the generated file's directory must already be writable by the container UID.

### Environment Variables

These are the environment variables which can be specified at container run time.

| Variable Name         | Description                                                               | Default                         | Available in   |
|-----------------------|---------------------------------------------------------------------------|---------------------------------|----------------|
| PUID                  | Server user ID in regular images; use `id -u` to find your host user ID   | 845                             | Regular images |
| PGID                  | Server group ID in regular images; use `id -g` to find your host group ID | 845                             | Regular images |
| GENERATE_NEW_SAVE     | Generate a new save if one does not exist before starting the server      | false                           | 0.17+          |
| LOAD_LATEST_SAVE      | Load latest when true. Otherwise load SAVE_NAME                           | true                            | 0.17+          |
| PORT                  | UDP port the server listens on                                            | 34197                           | 0.15+          |
| BIND                  | IP address (v4 or v6) the server listens on (IP\[:PORT])                  |                                 | 0.15+          |
| RCON_PORT             | TCP port the rcon server listens on                                       | 27015                           | 0.15+          |
| SAVE_NAME             | Name to use for the save file                                             | _autosave1                      | 0.17+          |
| PRESET                | Map generation preset when GENERATE_NEW_SAVE is true                      |                                 | 0.17+          |
| TOKEN                 | factorio.com token for mod updates (server listing uses settings JSON)    |                                 | 0.17+          |
| UPDATE_MODS_ON_START  | If mods should be updated before starting the server                      |                                 | 0.17+          |
| UPDATE_IGNORE         | Comma-separated list of mod names to skip during automatic updates        |                                 | 0.17+          |
| USERNAME              | factorio.com username for mod updates (server listing uses settings JSON) |                                 | 0.17+          |
| CONSOLE_LOG_LOCATION  | Saves the console log to the specifies location                           |                                 |                |
| DLC_SPACE_AGE         | Enables or disables the mods for DLC Space Age in mod-list.json[^1]       | true                            | 2.0.8+         |
| MODS                  | Mod directory to use                                                      | /factorio/mods                  | 2.0.8+         |
| SERVER_SETTINGS_FILE  | Absolute path to server settings                                          | `$CONFIG/server-settings.json`  | New builds     |
| SERVER_ID_FILE        | Absolute path to server identity                                          | `$CONFIG/server-id.json`        | New builds     |
| SERVER_ADMINLIST_FILE | Absolute path to the server admin list                                    | `$CONFIG/server-adminlist.json` | New builds     |
| SERVER_BANLIST_FILE   | Absolute path to the server ban list                                      | `$CONFIG/server-banlist.json`   | New builds     |
| SERVER_WHITELIST_FILE | Absolute path to the server whitelist                                     | `$CONFIG/server-whitelist.json` | New builds     |

**Note:** All environment variables are compared as strings. Quote YAML mapping values, for example `DLC_SPACE_AGE: "false"`. In list syntax, quote the whole item (`- "DLC_SPACE_AGE=elevated-rails"`), not only the value: `- DLC_SPACE_AGE="elevated-rails"` passes literal quotation marks to the container.

An explicit port in `BIND` overrides `PORT`, for example `127.0.0.1:34201` or `[::1]:34201`. A bare IPv6 address still uses `PORT`.

#### Host file ownership

The regular image starts as root, adjusts ownership inside `/factorio`, and runs the server as `PUID:PGID` (845:845 by default). To keep a bind-mounted data directory owned by your host user, set these to the numeric output of `id -u` and `id -g`. Changing them changes ownership of the mounted data, so use a dedicated directory—not your entire home directory.

Relative bind paths such as `./data:/factorio` are convenient but do not bypass filesystem permissions. With `--user`, a rootless container engine, or a rootless image, prepare the host directory for the actual container UID/GID and any user-namespace mapping. `PUID`/`PGID` do not change identity in the rootless image; its default is 1000:1000.

#### Server configuration paths

The `SERVER_*_FILE` overrides apply to regular and rootless images, including scenario startup. Upgrade or rebuild older images to use this feature. Unset or empty values use the defaults above; `$CONFIG` defaults to `/factorio/config`. The mod updater also reads credentials from `SERVER_SETTINGS_FILE` unless credentials are supplied explicitly or through Docker secrets.

Use absolute file paths, not directory paths. Existing settings are preserved; if `SERVER_SETTINGS_FILE` is missing, the default settings are copied there. For example, `-e SERVER_SETTINGS_FILE=/factorio/config/private/settings.json` selects a separate settings file.

Parent directories are created when possible. Custom settings files must be readable by the server user. Files that Factorio updates (including its server ID and player lists), and their parent directories, must be writable by that user. For paths outside `/factorio`, pre-create directories with the appropriate permissions: the regular image only adjusts ownership inside `/factorio`, and the rootless image does not adjust ownership. An existing read-only settings-file mount is supported; a missing settings file in a read-only directory is not.

#### PRESET Values

The `PRESET` environment variable is used when generating a new map (when `GENERATE_NEW_SAVE=true`). It corresponds to Factorio's built-in map generation presets. Common values include:

- `default` - Normal settings
- `rich-resources` - Resources are more abundant
- `marathon` - Recipes and technologies are more expensive
- `death-world` - Biters are more aggressive and numerous
- `death-world-marathon` - Combines death-world and marathon settings
- `rail-world` - Resources are further apart, encouraging train usage
- `ribbon-world` - Map height is limited for a unique challenge

If PRESET is not specified or left empty, the map will be generated using the settings from `map-gen-settings.json` and `map-settings.json` without a preset.

## Building images

Normal deployments should pull published images rather than build them. For development, run `python3 build.py --both` from the repository root to build regular and rootless variants. Add `--multiarch --push-tags` only when you intend to publish images and have registry credentials configured.

Use `--changed-from GIT_REF` to build only releases with new versions, changed archive checksums or added tags. Removing a tag alone does not trigger a rebuild. Automatic release updates use this mode; runtime/build-source changes and manual workflow runs rebuild all current versions.

Omit `--changed-from` to retry a failed publication or refresh base layers.

## Container Details

The philosophy is to [keep it simple](http://wiki.c2.com/?KeepItSimple).

* The server should bootstrap itself.
* Prefer configuration files over environment variables.
* Use one volume for data.

### Volumes

To keep things simple, the container uses a single volume mounted at `/factorio`. This volume stores configuration, mods, and saves.

The files in this volume should be owned by the factorio user, uid 845.

```text
  factorio
  |-- config
  |   |-- map-gen-settings.json
  |   |-- map-settings.json
  |   |-- rconpw
  |   |-- server-adminlist.json
  |   |-- server-banlist.json
  |   |-- server-settings.json
  |   `-- server-whitelist.json
  |-- mods
  |   `-- fancymod.zip
  `-- saves
      `-- _autosave1.zip
```

## Docker Compose

Use the current [Docker Compose plugin](https://docs.docker.com/compose/install/) (`docker compose`) and the repository-root [docker-compose.yml](docker-compose.yml). It runs the published `factoriotools/factorio:stable` image and stores data in `./data` alongside the Compose file. No source build, `VERSION` build argument or download checksum is needed.

```shell
git clone https://github.com/factoriotools/factorio-docker.git
cd factorio-docker
docker compose up -d
docker compose logs factorio
docker compose stop factorio
```

Before restarting, configure `data/config/server-settings.json`: set `visibility.public` to `false` for an unlisted server, or supply valid Factorio `username` and `token` for public listing. Set a game password or whitelist as appropriate. `USERNAME` and `TOKEN` environment variables normally configure the **mod updater**, not public listing; use the JSON file or the explicit provisioning wrapper above for server settings. See host file ownership above if you cannot edit the generated files.

```shell
docker compose up -d factorio
```

To update, back up `data` first, then pull and recreate the service **in the same Compose directory with the same volume mapping**:

```shell
docker compose pull factorio
docker compose up -d factorio
```

The image tag selects the game version. Use `stable` for the current stable release or pin a version compatible with your clients; `latest` may be experimental. Pulling a new image alone does not replace an existing container. Do not delete the data directory during an update.

[`docker/docker-compose.yml`](docker/docker-compose.yml) is a **developer source-build example**, not the normal installation path. Its `VERSION`, `SHA256` and optional `SHA256_ARM64` arguments verify downloaded game archives. Keep checksum verification enabled when building from source; use the published-image example if you do not want to maintain build arguments.

### Ports

* `34197/udp` - Game server (required). This can be changed with the `PORT` environment variable.
* `27015/tcp` - RCON (optional).

## LAN Games

Ensure the `lan` setting in server-settings.json is `true`.

```json
  "visibility":
  {
    "public": false,
    "lan": true
  },
```

Start the container with the `--network=host` option so clients can automatically find LAN games. Refer to the Quick Start to create the `/opt/factorio` directory.

```shell
sudo docker run -d \
  --network=host \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=unless-stopped  \
  factoriotools/factorio
```

## Deploy to other plaforms

### Vagrant

[Vagrant](https://www.vagrantup.com/) is a easy way to setup a virtual machine (VM) to run Docker. The [Factorio Vagrant box repository](https://github.com/dtandersen/factorio-lan-vagrant) contains a sample Vagrantfile.

For LAN games the VM needs an internal IP in order for clients to connect. One way to do this is with a public network. The VM uses DHCP to acquire an IP address. The VM must also forward port 34197.

```ruby
  config.vm.network "public_network"
  config.vm.network "forwarded_port", guest: 34197, host: 34197
```

### Amazon Web Services (AWS) Deployment

If you're looking for a simple way to deploy this to the Amazon Web Services Cloud, check out the [Factorio Server Deployment (CloudFormation) repository](https://github.com/m-chandler/factorio-spot-pricing). This repository contains a CloudFormation template that will get you up and running in AWS in a matter of minutes. Optionally it uses Spot Pricing so the server is very cheap, and you can easily turn it off when not in use.

### Azure Deployment

See [Factorio on Azure Container Instances](configs/Azure/README.md) for an ARM template and deployment instructions using Azure Files for persistent saves and configuration.

## Using a reverse proxy

If you need to use a reverse proxy you can use the following nginx snippet:

```
stream {
  server {
      listen 34197 udp reuseport;
      proxy_pass my.upstream.host:34197;
  }
}
```

If your factorio host uses multiple IP addresses (very common with IPv6), you might additionally need to bind Factorio to a single IP (otherwise the UDP proxy might get confused with IP mismatches). To do that pass the `BIND` envvar to the container: `docker run --network=host -e BIND=2a02:1234::5678 ...`

### Rootless Podman networking

For rootless Podman using **slirp4netns**, incorrect address or port discovery may be resolved by selecting the slirp4netns port handler:

```shell
podman run --network=slirp4netns:port_handler=slirp4netns \
  -p 34197:34197/udp \
  -v ./data:/factorio \
  factoriotools/factorio:stable
```

This selects the slirp4netns backend explicitly and requires it to be installed. According to [Podman's network documentation](https://docs.podman.io/en/latest/markdown/podman-run.1.html#network-mode-net), this handler preserves source IPs but is slower than the rootlesskit handler and cannot be used with user-defined networks. It is not a setting for the `pasta` backend, Docker Desktop, or your router. Host permissions, port forwarding and firewall rules still need to be correct; this workaround is not a guarantee for every NAT setup.

## Rootless Docker Support (Experimental)

> **Note**: Rootless support is currently experimental. Please report any issues you encounter.

If you're experiencing permission issues or want better security, consider using the rootless images. These images are designed to work seamlessly with rootless Docker installations and avoid common permission problems.

### What are Rootless Images?

The rootless images differ from regular images in several ways:
- Run as UID 1000 (non-root) by default
- No dynamic UID/GID mapping (PUID/PGID not supported)
- No runtime chown operations
- All directories created with open permissions during build

### Rootless Image Tags

Each regular tag has a corresponding rootless version with the `-rootless` suffix:
- `latest-rootless` (experimental)
- `stable-rootless` (experimental)
- `2.0.55-rootless` (experimental)

### Quick Start with Rootless

```shell
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v ~/factorio:/factorio \
  --name factorio \
  --restart=unless-stopped \
  factoriotools/factorio:stable-rootless
```

Key differences:
- No `chown` command needed
- No PUID/PGID environment variables
- Runs as UID 1000 by default
- No permission issues with volumes

### When to Use Rootless Images

Consider using rootless images if you:
- Are running Docker in rootless mode
- Experience permission issues with volume mounts
- Want to avoid containers running as root
- Don't need dynamic UID/GID mapping via PUID/PGID

### Limitations

- PUID/PGID environment variables are not supported
- Fixed to UID 1000 (may not match your host user)
- Experimental feature - may have undiscovered issues

## Troubleshooting

### Permission Issues

If you're experiencing permission errors such as:
- `chown: Operation not permitted`
- `Permission denied [/factorio/saves]`
- `Util.cpp:81: Operation not permitted`
- Files owned by unexpected UIDs (like 100844 instead of 845)

Please refer to our comprehensive [Permission Issues Guide](./PERMISSION_ISSUES_GUIDE.md) for detailed solutions. Common fixes include:
- **Updating Docker** to version 20.x or newer (this resolves many issues)
- **Using the rootless image** variants (e.g., `factoriotools/factorio:stable-rootless`)
- **Setting correct ownership** for your specific Docker configuration

### My server is listed in the server browser, but nobody can connect

Check the logs. If there is the line `Own address is RIGHT IP:WRONG PORT`, then this could be caused by the Docker proxy. If the the IP and port is correct it's probably a port forwarding or firewall issue instead.

By default, Docker routes traffic through a proxy. The proxy changes the source UDP port, so the wrong port is detected. See the forum post *[Incorrect port detected for docker hosted server](https://forums.factorio.com/viewtopic.php?f=49&t=35255)* for details.

To fix the incorrect port, start the Docker service with the `--userland-proxy=false` switch. Docker will route traffic with iptables rules instead of a proxy. Add the switch to the `DOCKER_OPTS` environment variable or `ExecStart` in the Docker systemd service definition. The specifics vary by operating system.

### When I run a server on a port besides 34197 nobody can connect from the server browser

Use the `PORT` environment variable to start the server on the a different port, .e.g. `docker run -e "PORT=34198"`. This changes the source port on the packets used for port detection. `-p 34198:34197` works fine for private servers, but the server browser detects the wrong port.

## Contributors

* [dtandersen](https://github.com/dtandersen) - Maintainer
* [Fank](https://github.com/Fankserver) - Programmer of the Factorio watchdog that keeps the version up-to-date.
* [SuperSandro2000](https://github.com/supersandro2000) - CI Guy, Maintainer and runner of the Factorio watchdog. Contributed version updates and wrote the Travis scripts.
* [DBendit](https://github.com/DBendit/docker_factorio_server) - Coded admin list, ban list support and contributed version updates
* [Zopanix](https://github.com/zopanix/docker_factorio_server) - Original Author
* [Rfvgyhn](https://github.com/Rfvgyhn/docker-factorio) - Coded randomly generated RCON password
* [gnomus](https://github.com/gnomus/docker_factorio_server) - Coded white listing support
* [bplein](https://github.com/bplein/docker_factorio_server) - Coded scenario support
* [jaredledvina](https://github.com/jaredledvina/docker_factorio_server) - Contributed version updates
* [carlbennett](https://github.com/carlbennett) - Contributed version updates and bugfixes

[^1]: Space Age mods can also be individually enabled by using their name separated by space.  
  Example 1: Enable all by using `true`
  Example 2: Enable all by listing the mod names `space-age elevated-rails quality`  
  Example 3: Enable only Elevated rails `elevated-rails`
