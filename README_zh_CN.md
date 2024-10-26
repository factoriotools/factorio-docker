# Factorio-异星工厂 [![Build Status](https://travis-ci.org/factoriotools/factorio-docker.svg?branch=master)](https://travis-ci.org/factoriotools/factorio-docker) ![Updater status](https://img.shields.io/endpoint?label=Updater%20status&logo=a&url=https%3A%2F%2Fhealthchecks.supersandro.de%2Fbadge%2F1a0a7698-445d-4e54-9e4b-f61a1544e01f%2FBO8VukOA%2Fmaintainer.shields) [![Docker Version](https://images.microbadger.com/badges/version/factoriotools/factorio.svg)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Pulls](https://img.shields.io/docker/pulls/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Stars](https://img.shields.io/docker/stars/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/) [![Microbadger Layers](https://images.microbadger.com/badges/image/factoriotools/factorio.svg)](https://microbadger.com/images/factoriotools/factorio "Get your own image badge on microbadger.com")

版本信息可以在[这里](https://github.com/factoriotools/factorio-docker/blob/master/README.md#factorio------)找到

## 标签描述

* `latest` - 最新版本 (可能含有实验性功能).
* `stable` - 最新的稳定版本 [factorio.com](https://www.factorio.com).
* `0.x`    - 某个分支上的最新版本
* `0.x.y` - 具体的版本
* `0.x-z` - 在该版本上的增量更新

## 什么是 Factorio？

> 摘录自 [steam factorio 页面](https://store.steampowered.com/app/427520/Factorio/)

「异星工厂」Factorio 是一款建造工业生产流水线并保持其高效运转的游戏。

在游戏中，你可以抠矿、搞科研、盖工厂、建设自动生产流水线，同时还要与异星虫子们互相伤害。

你将从一无所有艰辛起步。挥斧砍树，抡镐抠矿，手搓机械臂和传送带，然而像这样一直搞下去并没有什么卵用。因此，你需要高效的大规模发电厂，庞大的石油化工体系，壮观的全自动化产业链，以及替你东奔西走的机器人大队，让你成为物资储备丰盈工业帝国的真正操控者！

然而，总有一群刁民想害你。这个星球上的土著虫群对你在自家后院里瞎折腾的行为很不爽，总有一天这群刁民会联合起来找你麻烦。因此，你要制造武器、建立防御、准备镇压，让它们知道谁才是真正的主宰者。

你可以在多人游戏中加入不同的阵营，在大触们的带领下与朋友们分工协作， 一起建设恢弘无比的工业园区。

Factorio的模组支持吸引了全世界的设计师参与到对游戏的完善和革新中来，从优化调整到游戏辅助，甚至对游戏的彻底翻新，日新月异的模组将为你不断提供新的乐趣。
除了游戏核心的自由模式和沙盒模式之外，任务包还提供了更多不同形式的游戏挑战，这已经作为一个免费的DLC提供给玩家了。

对随机生成的地图不满意？不满足于原生游戏任务？这都不是事儿。通过内置的地图编辑器，你可以任意修改地图，配置地形、建筑、敌人等各种元素。如果你是大触，还可以添加自定义脚本，让你的游戏更具独创性、更加阴吹思婷！

**注意**：这个仓库仅包含游戏服务端. 游戏本体可以在 [factorio.com](factorio.com)、 [Steam](https://store.steampowered.com/app/427520/Factorio/)、[GOG.com](https://www.gog.com/game/factorio) 和 [Humble Bundle](https://www.humblebundle.com/store/factorio) 上找到。

## 使用方法

### 快速入门

运行服务端以在指定目录下生成必要的配置文件以及存档，`/opt/factorio` 也许是一个不错的选择。

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

这样一来， 服务端会使用 `/opt/factorio/saves` 中最新的存档进行游戏。

你一定想知道上面那些咒语是什么意思：

* `-d` - 以守护进程方式运行 ("detached")。
* `-p` - 暴露宿主机 (host) 某些端口。
* `-v` - 将宿主机中 `/opt/factorio` 目录挂载到docker容器的 `/factorio` 目录。
* `--restart` - 在宿主重启或服务端运行崩溃后重启服务端。
* `--name` - 将docker容器命名为 "factorio" (否则docker会给他随机起一个搞怪名字)。

`chown` 命令用来更改服务端所在目录的所有权用户以及用户组，为了安全起见我们并不希望游戏直接在root用户权限下运行，因此将用户id更改为845，从而服务端允许该用户在目录中进行读、写、运行操作。

查看日志以搞清楚发生了什么。

```shell
docker logs factorio
```

停止docker容器 (服务端)。

```shell
docker stop factorio
```

在运行过服务端之后可以在 `/opt/factorio/config` 目录中找到 `server-settings.json` 文件，修改改文件以定制你自己的服务端。

```shell
docker start factorio
```

现在试试连接服务端。如果没有正常运行的话请按照上面步骤查看日志。

### Console-终端

为了运行在服务端终端中运行命令，需要通过 `-it` 参数在交互模式下启动服务端。通过 `docker attach` 连接终端从而可以输入命令。

```shell
docker run -d -it \
  --name factorio \
  factoriotools/factorio
  
docker attach factorio
```

### 升级服务端

在升级服务端之前请务必**备份存档**，在客户端（也就是你的游戏中）备份存档相当容易（保存就好）。

请确保在启动服务端时使用了 `-v` 参数，从而服务端将会把存档写在你指定的挂在目录中。`docker rm` 命令会彻底删除运行 facotrio 服务端的容器，也同时会删除容器的整个文件系统实例，因此如果没有挂载外部目录的话，存档也会被删除哦。

```shell
docker stop factorio
docker rm factorio
docker pull factoriotools/factorio
```

然后就像前面说的那样启动服务端，大概一分钟后新的服务端就已经在运行中啦，并且存档和设置还和原来一样！

### 存档

在第一次运行服务端的时候，服务端会根据 `/opt/factorio/config` 目录中的 `map-gen-settings.json` 和 `map-settings.json` 配置文件的内容，在 `/opt/factorio/saves` 目录下会生成一张新地图（存档）`_autosave1.zip`。之后如果在停掉之后再次运行，服务端会载入最新的存档。

如果想要运行一个旧存档，你需要停止运行中的服务端，并且运行一个命令 `touch oldsave.zip`。 这会重置其日期，然后重新启动服务端。或者你可以通过删除所有其他存档只留下想要运行的存档来完成同样的目的。

如果想生成一个新的存档，你需要停止运行中的服务端，然后删除所有的存档再启动服务端就好。

#### 在运行命令中直接指定存档（需要 0.17.79-2+ 版本）

你可以在启动服务端时通过设置一个特殊的环境变量来载入一个特定的存档：

设置 `SAVE_NAME` 为 `saves` 中你想运行的存档名，去掉 `.zip` 后缀：

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e LOAD_LATEST_SAVE=false \
  -e SAVE_NAME=replaceme \
  --name factorio \
  --restart=always \
  factoriotools/factorio
```

若要生成一个新存档，设置 `GENERATE_NEW_SAVE=true`，同时指定存档名 `SAVE_NAME`：

```shell
sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  -e LOAD_LATEST_SAVE=false \
  -e GENERATE_NEW_SAVE=true \
  -e SAVE_NAME=replaceme \
  --name factorio \
  --restart=always \
  factoriotools/factorio
```

### Mods-模组

将模组拷贝至 `mods` 目录下，然后重启服务端即可。

对于 `0.17` 及以上版本，新增 `UPDATE_MODES_ON_START` 环境变量，如果将其设置为 `true`，在服务端启动时将会更新所有的模组。请注意，应用此设置时，必须通过 docker secrets、环境变量或者在 `server-settings.json` 中填写相应字段来提供一个合法的 [Facotrio 用户名以及 Token](https://www.factorio.com/profile)，否则服务端就不会启动。

### Scenarios-场景

如果你希望新启动一个场景（而不是从某一个存档中启动），你需要通过另一个备选 `entrypoint` 来启动我们的 factorio-docker 镜像：通过运行以下命令，使用 `/factorio/entrypoints` 目录中的示例 entrypoint 文件来启动服务端。仔细观察后就能发现这只是在之前的命令基础上增加了 `--entrypoint` 设置并在最后新增了一个参数用来指示 `scenarios` 目录中想要启动的场景的文件名。


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

### 将场景转换为常规地图

如果你想把你的场景导出为一个常规的地图存档，类似启动一个新的场景，我们可以通过一个备选 `entrypoint` 文件来达到这个效果：服务端在运行后会将场景转换成一个常规地图存档放置在你的 `saves` 目录中，然后你就可以像平常那样启动服务端了。

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

在 config/rconpw 文件中设置RCON密码。 如果 rconpw 文件不存在，将会自动生成含有随机密码的该文件。

如果想要更改密码，请停止服务端，编辑rconpw文件并重启服务端。

如果想要禁用RCON，请不要在启动命令中加入 -p 27015:27015/tcp 参数，在宿主机（服务器）中停止暴露rcon端口，这时，RCON将继续在docker容器中运行，但不可达。


### 白名单 (0.15.3+)

创建文件 `config/server-whitelist.json` 然后将用户名加入到该json中。

```json
[
    "you",
    "friend"
]
```

### 黑名单 (0.17.1+)

创建文件 `config/server-banlist.json` 然后将用户名加入到该json中。

```json
[
    "bad_person",
    "other_bad_person"
]
```

### 管理员列表 (0.17.1+)

创建文件 `config/server-adminlist.json` 然后将用户名加入到该json中。

```json
[
    "you",
    "friend"
]
```

### 自定义配置文件 (0.17.x+)

原始的 factorio 服务端并不支持在配置文件中添加环境变量，这里提供一个变通办法：通过在 docker-compose 中使用 `envsubst` 命令，在服务端启动时根据环境变量来动态生成配置文件：

下面的例子将用相应的环境变量来填充 `server-settings.json` 中的字段。

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

`server-settings.json` 中可能提供一些供环境变量来替换的字段：

```json
"name": "${INSTANCE_NAME}",
"description": "${INSTANCE_DESC}",
```

### 容器相关的细节

[保持简单](http://wiki.c2.com/?KeepItSimple)的哲学。

+ 服务端应当可以自启动
+ 在环境变量和配置文件中倾向于配置文件
+ 只使用一个数据卷（挂载目录）

### 数据卷

为了保持简单，我们的 docker 服务端只使用一个数据卷挂载到容器中的 `/factorio` 目录。其中包含了所有的配置，模组和存档。

在这个数据卷中所有的文件应当被 uid 为 845 的 factorio 专有用户所拥有（为了安全）

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

### Docker Compose

[Docker Compose](https://docs.docker.com/compose/install/) 提供了一种便捷的容器运行方式。

首先获取一个 [docker-compose.yml](https://github.com/factoriotools/factorio-docker/blob/master/0.17/docker-compose.yml) 文件。假设你准备使用我们提供的：

```shell
git clone https://github.com/factoriotools/factorio-docker.git
cd docker_factorio_server/0.17
```

或者假设你想自己编写一个：

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

现在通过 cd 命令进入到 `docker-compose.yml` 所在的目录然后运行下面的命令：

```shell
sudo mkdir -p /opt/factorio
sudo chown 845:845 /opt/factorio
sudo docker-compose up -d
```

### 端口

- `34197/udp` - 游戏服务端（必要）。可以通过改变 `PORT` 环境变量来改变。
- `27015/tcp` - RCON（可选）。

## 局域网游戏

确保 `server-settings.json` 中的 `lan` 字段被设置为 `true`。

```shell
  "visibility":
  {
    "public": false,
    "lan": true
  },
```

在启动服务端时假如 `--network=host` 参数，从而客户端可以自动找到局域网游戏，参考 快速入门 章节。

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

## 在其他平台上部署

### Vagrant

[Vagrant](https://www.vagrantup.com/) 是一种通过虚拟机来运行 Docker 的便捷方式。 在 [Factorio Vagrant box repository](https://github.com/dtandersen/factorio-lan-vagrant) 中有一个示例的 Vagrantfile。

对于局域网游戏，Vagrant 虚拟机需要一个内部 IP 从而使游戏可达。一种方式是通过在一个空开网络中部署。虚拟机使用 DHCP 方式来获取一个 IP 地址。同时必须转发到 34197 端口。

```ruby
  config.vm.network "public_network"
  config.vm.network "forwarded_port", guest: 34197, host: 34197
```

### AWS 部署

如果你想找一个傻瓜教程，请看这个[仓库](https://github.com/m-chandler/factorio-spot-pricing)。这个仓库中包含一个可以让你在几分钟内在 AWS 上搭建服务端的 CloudFormation 模板。同时它支持 Spot Pricing 因此费用会非常便宜，而且你可以在不用的时候把服务器关掉。

## 疑难杂症

### 我可以在服务器列表中看到我的服务器但就是无法连接

查看 log，如果有一行说 `Own address is RIGHT IP:WRONG PORT`，那么这个问题就有可能是 Docker Proxy 导致的。 如果 IP 和端口都是正确的，那么有可能是端口转发或者防火墙出了问题。

在默认情况下，Docker 通过一个代理来转发网络请求。这个代理会改变 UDP 端口，因此会监测到上面的端口错误。更多细节请移步 *[Incorrect port detected for docker hosted server](https://forums.factorio.com/viewtopic.php?f=49&t=35255)*。

为了修复错误端口问题，在启动 Docker 服务时加上 `--userland-proxy=false`。这样一来 Docker 就会通过 iptables 来转发请求从而不走代理。可以通过设置 `DOCKER_OPTS` 环境变量或者改变 Docker systemd service 中的 `ExecStart` 字段来添加这一参数。不同的操作系统可能有不同的配置方式。

### 我不用 34197 端口就没人可以连我的服务器

如果一定要改端口，请使用 `PORT` 环境变量更改。例如 `docker run -e PORT=34198`。这样会更改端口监测中的目标端口。通过 `-p 34198:34197` 方式更改端口对于私人服务器来说是可行的，但这样一来服务器浏览器就没有办法检测到正确的端口了。

## 贡献者

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
* [Thrimbda](https://github.com/Thrimbda) - 中文翻译
