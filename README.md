# Factorio [![](https://images.microbadger.com/badges/image/dtandersen/factorio.svg)](https://microbadger.com/images/dtandersen/factorio "Get your own image badge on microbadger.com") [![Docker Pulls](https://img.shields.io/docker/pulls/dtandersen/factorio.svg)](https://hub.docker.com/r/dtandersen/factorio/) [![Docker Stars](https://img.shields.io/docker/stars/dtandersen/factorio.svg)](https://hub.docker.com/r/dtandersen/factorio/)

* `0.15.3`, `0.15`, `latest` [(0.15/Dockerfile)](https://github.com/dtandersen/docker_factorio_server/blob/master/0.15/Dockerfile)
* `0.14.23`, `0.14`, `stable` [(0.14/Dockerfile)](https://github.com/dtandersen/docker_factorio_server/blob/master/0.14/Dockerfile)
* `0.13.20`, `0.13`  [(0.13/Dockerfile)](https://github.com/dtandersen/docker_factorio_server/blob/master/0.13/Dockerfile)

*Tag descriptions*

* `latest` - highest version: may be experimental.
* `stable` - highest version declared stable.
* `0.x` - highest version in a branch: may be experimental.
* `0.x.y` - a specific version.
* `0.x-dev` - whatever is in master for that version.


# What is Factorio?

[Factorio](https://www.factorio.com) is a game in which you build and maintain factories.

You will be mining resources, researching technologies, building infrastructure, automating production and fighting enemies. Use your imagination to design your factory, combine simple elements into ingenious structures, apply management skills to keep it working and finally protect it from the creatures who don't really like you.

The game is very stable and optimized for building massive factories. You can create your own maps, write mods in Lua or play with friends via Multiplayer.

NOTE: This is only the server. The game is available at [factorio.com](https://www.factorio.com) and [Steam](http://store.steampowered.com/app/427520/).


# Usage

## Quick Start

Run the server to create the necessary folder structure and configuration files. For this example data is stored in `/tmp/factorio`.

```
docker run -d -p 34197:34197/udp -p 27015:27015/tcp \
  -v /tmp/factorio:/factorio \
  --name factorio \
  --restart=always  \
  dtandersen/factorio
```

For those new to Docker, here is an explanation of the options:

* `-d` - Run as a daemon ("detached").
* `-p` - Expose ports.
* `-v` - Mount `/tmp/factorio` on the local file system to `/factorio` in the container.
* `--restart` - Restart the server if it crashes and at system start
* `--name` - Name the container "factorio" (otherwise it has a funny random name).

Check the logs to see what happened:

```
docker logs factorio
```

Stop the server:

```
docker stop factorio
```

Now there's a `server-settings.json` file in the folder `/tmp/factorio/config`. Modify this to your liking and restart the server:

```
docker start factorio
```

Try to connect to the server. Check the logs if it isn't working.


## Console

To issue console commands to the server, start the server in interactive mode with `-it`. Open the console with `docker attach` and then type commands.

	docker run -d -it  \
        --name factorio \
        dtandersen/factorio
	docker attach factorio


## Upgrading

Before upgrading backup the save. It's easy to make a save in the client.

Ensure `-v` was used to run the server so the save is outside of the Docker container. The `docker rm` command completely destroys the container, which includes the save if it isn't stored in an data volume.

Delete the container and refresh the image:

	docker stop factorio
	docker rm factorio
	docker pull dtandersen/factorio

Now run the server as before. In about a minute the new version of Factorio should be up and running, complete with saves and config!


## Saves

A new map named `_autosave1.zip` is generated the first time the server is started. The `map-gen-settings.json` file in `/tmp/factorio/config` is used for the map settings. On subsequent runs the newest save is used.

To load an old save stop the server and run the command `touch oldsave.zip`. This resets the date. Then restart the server. Another option is to delete all saves except one.

To generate a new map stop the server, delete all of the saves and restart the server.


## Mods

Copy mods into the mods folder and restart the server.


## RCON

Set the RCON password in the `rconpw` file. A random password is generated if `rconpw` doesn't exist.

To change the password, stop the server, modify `rconpw`, and restart the server.

To "disable" RCON don't expose port 27015, i.e. start the server without `-p 27015:27015/tcp`. RCON is still running, but nobody can to connect to it.


## Whitelisting (0.15.3+)

Create file `config/server-whitelist.json` and add the whitelisted users.

    [
		"you",
		"friend"
	]

# Container Details

The philosophy is to [keep it simple](http://wiki.c2.com/?KeepItSimple).

* The server should bootstrap itself.
* Prefer configuration files over environment variables.
* Use one volume for data.


## Volumes

To keep things simple, the container uses a single volume mounted at `/factorio`. This volume stores configuration, mods, and saves.

    factorio
    |-- config
    |   |-- map-gen-settings.json
    |   |-- rconpw
    |   |-- server-settings.json
    |   `-- server-whitelist.json
    |-- mods
    |   `-- fancymod.zip
    `-- saves
        `-- _autosave1.zip


## Ports

* `34197/udp` - Game server (required).
* `27015/tcp` - RCON (optional).


## Environment Variables

* `PORT` (0.15+) - Start the server on an alterate port, .e.g. `docker run -e "PORT=34198"`.


## Troubleshooting

**My server is listed in the server browser, but nobody can connect**

Check the logs. If there is the line `Own address is RIGHT IP:WRONG PORT`, then this could be caused by the Docker proxy. If the the IP and port is correct it's probably a port forwarding or firewall issue instead.

By default, Docker routes traffic through a proxy. The proxy changes the source UDP port, so the wrong port is detected. See the forum post *[Incorrect port detected for docker hosted server](https://forums.factorio.com/viewtopic.php?f=49&t=35255)* for details.

To fix the incorrect port, start the Docker service with the `--userland-proxy=false` switch. Docker will route traffic with iptables rules instead of a proxy. Add the switch to the `DOCKER_OPTS` environment variable or `ExecStart` in the Docker systemd service definition. The specifics vary by operating system.

**When I run a server on a port besides 34197 nobody can connect from the server browser**

Use the `PORT` environment variable to start the server on the a different port, .e.g. `docker run -e "PORT=34198"`. This changes the source port on the packets used for port detection. `-p 34198:34197` works fine for private servers, but the server browser detects the wrong port.


# Contributors

* [dtandersen](https://github.com/dtandersen/docker_factorio_server) - Maintainer
* [Zopanix](https://github.com/zopanix/docker_factorio_server) - Originator
* [Rfvgyhn](https://github.com/Rfvgyhn/docker-factorio) - Randomly generate RCON password
* [gnomus](https://github.com/gnomus/docker_factorio_server) - White listing
* [jaredledvina](https://github.com/jaredledvina/docker_factorio_server) - Version update
