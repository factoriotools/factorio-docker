# Factorio [![Build Status](https://travis-ci.org/factoriotools/factorio-docker.svg?branch=master)](https://travis-ci.org/factoriotools/factorio-docker) ![Updater status](https://img.shields.io/endpoint?label=Updater%20status&logo=a&url=https%3A%2F%2Fhealthchecks.supersandro.de%2Fbadge%2F1a0a7698-445d-4e54-9e4b-f61a1544e01f%2FBO8VukOA%2Fmaintainer.shields) [![Docker Version](https://images.microbadger.com/badges/version/factoriotools/factorio.svg)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Pulls](https://img.shields.io/docker/pulls/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Stars](https://img.shields.io/docker/stars/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/) [![Microbadger Layers](https://images.microbadger.com/badges/image/factoriotools/factorio.svg)](https://microbadger.com/images/factoriotools/factorio "Get your own image badge on microbadger.com")

* `0.18.1`, `0.18`, `latest` [(0.18/Dockerfile)](https://github.com/factoriotools/factorio-docker/blob/master/0.18/Dockerfile)
* `0.17.79`, `0.17`, `stable` [(0.17/Dockerfile)](https://github.com/factoriotools/factorio-docker/blob/master/0.17/Dockerfile)
* `0.16.51`, `0.16` [(0.16/Dockerfile)](https://github.com/factoriotools/factorio-docker/blob/master/0.16/Dockerfile)
* `0.15.40`, `0.15` [(0.15/Dockerfile)](https://github.com/factoriotools/factorio-docker/blob/master/0.15/Dockerfile)
* `0.14.23`, `0.14` [(0.14/Dockerfile)](https://github.com/factoriotools/factorio-docker/blob/master/0.14/Dockerfile)

## Tag descriptions

* `latest` - most up-to-date version (may be experimental).
* `stable` - version declared stable on [factorio.com](https://www.factorio.com).
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
  --restart=always \
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
docker stop factorio
```

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

### Upgrading

Before upgrading backup the save. It's easy to make a save in the client.

Ensure `-v` was used to run the server so the save is outside of the Docker container. The `docker rm` command completely destroys the container, which includes the save if it isn't stored in an data volume.

Delete the container and refresh the image:

```shell
docker stop factorio
docker rm factorio
docker pull factoriotools/factorio
```

Now run the server as before. In about a minute the new version of Factorio should be up and running, complete with saves and config!

### Saves

A new map named `_autosave1.zip` is generated the first time the server is started. The `map-gen-settings.json` and `map-settings.json` files in `/opt/factorio/config` are used for the map settings. On subsequent runs the newest save is used.

To load an old save stop the server and run the command `touch oldsave.zip`. This resets the date. Then restart the server. Another option is to delete all saves except one.

To generate a new map stop the server, delete all of the saves and restart the server.

#### Specify a save directly (0.17.79-2+)

You can specify a specific save to load by configuring the server through a set of environment variables:

To load an existing save set `SAVE_NAME` to the name of your existing save file located within the `saves` directory, without the `.zip` extension:

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e ENABLE_SERVER_LOAD_LATEST=false \
  -e SAVE_NAME=replaceme \
  --name factorio \
  --restart=always \
  factoriotools/factorio
```

To generate a new map set `ENABLE_GENERATE_NEW_MAP_SAVE=true` and specify `SAVE_NAME`:

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e ENABLE_SERVER_LOAD_LATEST=false \
  -e ENABLE_GENERATE_NEW_MAP_SAVE=true \
  -e SAVE_NAME=replaceme \
  --name factorio \
  --restart=always \
  factoriotools/factorio
```

### Mods

Copy mods into the mods folder and restart the server.

As of 0.17 a new environment variable was added ``UPDATE_MODS_ON_START`` which if set to ``true`` will cause the mods get to updated on server start. If set a valid [Factorio Username and Token](https://www.factorio.com/profile) must be supplied or else the server will not start. They can either be set as docker secrets, environment variables, or pulled from the server-settings.json file.

### Scenarios

If you want to launch a scenario from a clean start (not from a saved map) you'll need to start the docker image from an alternate entrypoint. To do this, use the example entrypoint file stored in the /factorio/entrypoints directory in the volume, and launch the image with the following syntax. Note that this is the normal syntax with the addition of the --entrypoint setting AND the additional argument at the end, which is the name of the Scenario in the Scenarios folder.

```shell
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=always  \
  --entrypoint "/scenario.sh" \
  factoriotools/factorio \
  MyScenarioName
```

### Converting Scenarios to Regular Maps

If you would like to export your scenario to a saved map, you can use the example entrypoint similar to the Scenario usage above. Factorio will run once, converting the Scenario to a saved Map in your saves directory. A restart of the docker image using the standard options will then load that map, just as if the scenario were just started by the Scenarios example noted above.

```shell
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=always  \
  --entrypoint "/scenario2map.sh" \
  factoriotools/factorio
  MyScenarioName
```

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

Out-of-the box, factorio does not support environment variables inside the configuration files. A workaround is the usage of `envsubst` which generates the configuration files dynamically during startup from environment variables set in docker-compose:

Example which replaces the server-settings.json:

```yaml
factorio_1:
  image: factoriotools/factorio
  ports:
    - "34197:34197/udp"
  volumes:
   - /opt/factorio:/factorio
   - ./server-settings.json:/server-settings.json
  environment:
    - INSTANCE_NAME=Your Instance's Name
    - INSTANCE_DESC=Your Instance's Description
  entrypoint: /bin/sh -c "mkdir -p /factorio/config && envsubst < /server-settings.json > /factorio/config/server-settings.json && exec /docker-entrypoint.sh"
```

The `server-settings.json` file may then contain the variable references like this:

```json
"name": "${INSTANCE_NAME}",
"description": "${INSTANCE_DESC}",
```

### configuration file generation

It is possible, by setting GENERATE_SETTINGS_FILES to true, to generate the server-settings.json, map-gen-settings.json and some of map-settings.json files based on environment variables. The tables below describe the different variables avaliable.


### Environment Variables

|Variable											|default				|description|
|---------------------------------------------------|:---------------------:|-----------|
|__**META VARIABLES**__								|						|variables used for configuration of the container itself, or used in the scripts to determine functionality. |
|SAVE_NAME											|						|the name of the game save|
|ENABLE_SERVER_LOAD_LATEST							|true					||
|ENABLE_GENERATE_NEW_MAP_SAVE						|false					||
|GENERATE_SETTINGS_FILES							|false					|if 'true', the server settings files will be generated based on the environment variables or defaults. Otherwise, tbe files will be copied from the files in /opt/factorio/data|
|GENERATE_SETTINGS_FILES_DEBUG						|false					|if 'true', any variables that are set will output when used in the settings files generation.|
|FORCE_GENERATE_SETTINGS_FILES						|false					|If 'true', the settings files will be generated from the environment variables, regardless of if the files exist already.|
|__**SERVER SETTINGS**__							|						|server-settings.json|
|TEMPLATE_SERVER_NAME								|my-server				|Name of the game as it will appear in the game listing|
|TEMPLATE_SERVER_DESCRIPTION						|my-server				|Description of the game that will appear in the listing|
|TEMPLATE_SERVER_TAGS								|"factorio","docker"	|Game tags|
|TEMPLATE_SERVER_MAX_PLAYERS						|0						|Maximum number of players allowed, admins can join even a full server. 0 means unlimited.|
|TEMPLATE_SERVER_PUBLIC_VISIBILITY					|true					|Game will be published on the official Factorio matching server|
|TEMPLATE_SERVER_LAN_VISIBILITY						|true					|Game will be broadcast on LAN|
|TEMPLATE_SERVER_USERNAME							|						|Your factorio.com login Username. Required for games with visibility public|
|TEMPLATE_SERVER_PASSWORD							|						|Your factorio.com login Password. Required for games with visibility public|
|TEMPLATE_SERVER_TOKEN								|						|Authentication token. May be used instead of 'password' above.|
|TEMPLATE_SERVER_GAME_PASSWORD						|						|The password that the server |
|TEMPLATE_SERVER_REQUIRE_USER_VERIFICATION			|true					|When set to true, the server will only allow clients that have a valid Factorio.com account|
|TEMPLATE_SERVER_MAX_UPLOAD							|0						|Default value is 0. 0 means unlimited. Value is in Kilobytes per second.|
|TEMPLATE_SERVER_MAX_UPLOAD_SLOTS					|5						|Default value is 5. 0 means unlimited.|
|TEMPLATE_SERVER_MIN_LATENCY_TICKS					|0						|One tick is 16ms in default speed, default value is 0. 0 means no minimum.|
|TEMPLATE_SERVER_IGNORE_LIMIT_FOR_RETURNING			|false					|Players that played on this map already can join even when the max player limit was reached.|
|TEMPLATE_SERVER_ALLOW_COMMANDS						|admins-only			|The ability for commands to be used on the server. Possible values are, true, false and admins-only|
|TEMPLATE_SERVER_AUTOSAVE_INTERVAL					|5						|Autosave interval in minutes|
|TEMPLATE_SERVER_AUTOSAVE_SLOTS						|3						|Server autosave slots, it is cycled through when the server autosaves.|
|TEMPLATE_SERVER_AFK_KICK_INTERVAL					|0						|How many minutes until someone is kicked when doing nothing, 0 for never.|
|TEMPLATE_SERVER_AUTOPAUSE							|true					|Whether should the server be paused when no players are present.|
|TEMPLATE_SERVER_ADMIN_ONLY_PAUSE					|true					|Whether only admins can pause the game.|
|TEMPLATE_SERVER_SERVER_ONLY_AUTOSAVE				|true					|Whether autosaves should be saved only on server or also on all connected clients. |
|TEMPLATE_SERVER_NONBLOCKING_SAVE					|false					|Highly experimental feature, enable only at your own risk of losing your saves. On UNIX systems, server will fork itself to create an autosave. Autosaving on connected Windows clients will be disabled regardless of autosave_only_on_server option.|
|TEMPLATE_SERVER_MIN_SEGMENT_SIZE					|25						||
|TEMPLATE_SERVER_MIN_SEGMENT_SIZE_PEER				|20						||
|TEMPLATE_SERVER_MAX_SEGMENT_SIZE					|100					||
|TEMPLATE_SERVER_MAX_SEGMENT_SIZE_PEER				|10						||
|__**MAP GEN SETTINGS**__							|						|map-gen-settings.json|
|TEMPLATE_GEN_TERRAIN_SEGMENTATION					|1						|Inverse of map scale|
|TEMPLATE_GEN_TERRAIN_WATER							|1						|Multiplier for water 'coverage' - higher increases the water level. Water level = 10 * log2(this value)|
|TEMPLATE_GEN_MAP_WIDTH								|0						|Width of map, in tiles; 0 means infinite.|
|TEMPLATE_GEN_MAP_HEIGHT							|0						|Height of map, in tiles; 0 means infinite.|
|TEMPLATE_GEN_MAP_STARTING_AREA						|1						|Multiplier for 'biter free zone radius'|
|TEMPLATE_GEN_PEACEFULL_MODE						|false					||
|TEMPLATE_GEN_COAL_RICHNESS							|1						||
|TEMPLATE_GEN_COAL_SIZE								|1						||
|TEMPLATE_GEN_COAL_FREQUENCY						|1						||
|TEMPLATE_GEN_STONE_RICHNESS						|1						||
|TEMPLATE_GEN_STONE_SIZE							|1						||
|TEMPLATE_GEN_STONE_FREQUENCY						|1						||
|TEMPLATE_GEN_COPPER_RICHNESS						|1						||
|TEMPLATE_GEN_COPPER_SIZE							|1						||
|TEMPLATE_GEN_COPPER_FREQUENCY						|1						||
|TEMPLATE_GEN_IRON_RICHNESS							|1						||
|TEMPLATE_GEN_IRON_SIZE								|1						||
|TEMPLATE_GEN_IRON_FREQUENCY						|1						||
|TEMPLATE_GEN_URANIUM_RICHNESS						|1						||
|TEMPLATE_GEN_URANIUM_SIZE							|1						||
|TEMPLATE_GEN_URANIUM_FREQUENCY						|1						||
|TEMPLATE_GEN_CRUDE_RICHNESS						|1						||
|TEMPLATE_GEN_CRUDE_SIZE							|1						||
|TEMPLATE_GEN_CRUDE_FREQUENCY						|1						||
|TEMPLATE_GEN_TREES_RICHNESS						|1						||
|TEMPLATE_GEN_TREES_SIZE							|1						||
|TEMPLATE_GEN_TREES_FREQUENCY						|1						||
|TEMPLATE_GEN_BITER_RICHNESS						|1						||
|TEMPLATE_GEN_BITER_SIZE							|1						||
|TEMPLATE_GEN_BITER_FREQUENCY						|1						||
|TEMPLATE_GEN_CLIFF_NAME							|cliff					|Name of the cliff prototype.|
|TEMPLATE_GEN_CLIFF_ELEVATION_ZERO					|10						|Elevation of first row of cliffs.|
|TEMPLATE_GEN_CLIFF_ELEVATION_INTERVAL				|10						|Elevation difference between successive rows of cliffs.|
|TEMPLATE_GEN_CLIFF_RICHNESS						|1						|Multiplier for cliff continuity; 0 will result in no cliffs, 10 will make all cliff rows completely solid.|
|TEMPLATE_GEN_EXPRESSION_ELEVATION					|						|Overrides for property value generators. Elevation influences water and cliff placement. Leave it blank to get 'normal' terrain. Use '0_16-elevation' to reproduce terrain from 0.16. Use '0_17-island' to get an island.|
|TEMPLATE_GEN_AUX_BIAS								|0.300000				||
|TEMPLATE_GEN_AUX_MULTIPLIER						|1.333333				||
|TEMPLATE_GEN_MOISTURE_BIAS							|0.100000				||
|TEMPLATE_GEN_MOISTURE_MULTIPLIER					|0.500000				||
|TEMPLATE_GEN_STARTING_POINT_X						|1000					||
|TEMPLATE_GEN_STARTING_POINT_Y						|2000					||
|TEMPLATE_GEN_MAP_SEED								|null					|Use null for a random seed, number for a specific seed.|
|__**MAP SETTINGS**__								|						|map-settings.json|
|TEMPLATE_MAP_DIFFICULTY_RECIPE						|0						||
|TEMPLATE_MAP_DIFFICULTY_TECHNOLOGY					|0						||
|TEMPLATE_MAP_DIFFICULTY_TECH_PRICE					|1						||
|TEMPLATE_MAP_DIFFICULTY_RESEARCH_QUEUE				|after-victory			||
|TEMPLATE_MAP_POLLUTION_ENABLED						|true					||
|TEMPLATE_MAP_POLLUTION_DIFFUSION_RATIO				|0.02					||
|TEMPLATE_MAP_POLLUTION_MIN_TO_DEFUSE				|15						| amount that is diffused to neighboring chunk (these are values for 60 ticks (1 simulated second)).|
|TEMPLATE_MAP_POLLUTION_AGEING						|1						||
|TEMPLATE_MAP_POLLUTION_EXPECTED_MAX_PER_CHUNK		|150					||
|TEMPLATE_MAP_POLLUTION_MIN_TO_SHOW_PER_CHUNK		|50						||
|TEMPLATE_MAP_POLLUTION_MIN_TO_DAMAGE_TREES			|60						||
|TEMPLATE_MAP_POLLUTION_MAX_FOREST_DAMMAGE			|150					||
|TEMPLATE_MAP_POLLUTION_PER_TREE_DAMAGE				|50						||
|TEMPLATE_MAP_POLLUTION_RESTORED_PER_TREE_DAMAGE	|10						||
|TEMPLATE_MAP_POLLUTION_MAX_TO_RESTORE_TREES		|20						||
|TEMPLATE_MAP_POLLUTION_BITER_ATTACK_MODIFIER		|1						||
|TEMPLATE_MAP_EVOLUTION_ENABLED						|true					||
|TEMPLATE_MAP_EVOLUTION_TIME_FACTOR					|0.000004				||
|TEMPLATE_MAP_EVOLUTION_DESTROY_FACTOR				|0.002					||
|TEMPLATE_MAP_EVOLUTION_POLLUTION_FACTOR			|0.0000009				||
|TEMPLATE_MAP_EXPANSION_ENABLED						|true					||
|TEMPLATE_MAP_EXPANSION_MIN_BASE_SPACING			|3						||
|TEMPLATE_MAP_EXPANSION_MAX_EXPANSION_DISTANCE		|7						||
|TEMPLATE_MAP_EXPANSION_FRIENDLY_BASE_RADIUS		|2						||
|TEMPLATE_MAP_EXPANSION_BITER_BASE_RADIUS			|2						||
|TEMPLATE_MAP_EXPANSION_BUILDING_CFF				|0.1					||
|TEMPLATE_MAP_EXPANSION_OTHER_BASE_CFF				|2.0					||
|TEMPLATE_MAP_EXPANSION_NEIGHBOUR_CHUNK_CFF			|0.5					||
|TEMPLATE_MAP_EXPANSION_NEIGHBOUR_BASE_CHUNK_CFF	|0.4					||
|TEMPLATE_MAP_EXPANSION_MAX_COLLIDING_TILES_CFF		|0.9					||
|TEMPLATE_MAP_EXPANSION_SETTLER_GROUP_MIN			|5						||
|TEMPLATE_MAP_EXPANSION_SETTLER_GROUP_MAX			|20						||
|TEMPLATE_MAP_EXPANSION_MIN_COOLDOWN				|14400					||
|TEMPLATE_MAP_EXPANSION_MAX_COOLDOWN				|216000					||


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

[Docker Compose](https://docs.docker.com/compose/install/) is an easy way to run Docker containers.

First get a [docker-compose.yml](https://github.com/factoriotools/factorio-docker/blob/master/0.17/docker-compose.yml) file. To get it from this repository:

```shell
git clone https://github.com/factoriotools/factorio-docker.git
cd docker_factorio_server/0.17
```

Or make your own:

```shell
version: '2'
services:
  factorio:
    image: factoriotools/factorio
    ports:
     - "34197:34197/udp"
     - "27015:27015/tcp"
    volumes:
     - /opt/factorio:/factorio
```

Now cd to the directory with docker-compose.yml and run:

```shell
sudo mkdir -p /opt/factorio
sudo chown 845:845 /opt/factorio
sudo docker-compose up -d
```

### Ports

* `34197/udp` - Game server (required).
* `27015/tcp` - RCON (optional).

## LAN Games

Ensure the `lan` setting in server-settings.json is `true`.

```shell
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
  --restart=always  \
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

## Troubleshooting

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
* [gnomus](https://github.com/gnomus/docker_factorio_server) - Coded wite listing support
* [bplein](https://github.com/bplein/docker_factorio_server) - Coded scenario support
* [jaredledvina](https://github.com/jaredledvina/docker_factorio_server) - Contributed version updates
* [carlbennett](https://github.com/carlbennett) - Contributed version updates and bugfixes
* [deef0000dragon1](https://github.com/deef0000dragon1) - Contributed Environment Variable based settings file generation.
