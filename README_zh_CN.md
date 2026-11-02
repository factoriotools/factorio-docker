# Factorio [![Docker Version](https://img.shields.io/docker/v/factoriotools/factorio?sort=semver)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Pulls](https://img.shields.io/docker/pulls/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/) [![Docker Stars](https://img.shields.io/docker/stars/factoriotools/factorio.svg?maxAge=600)](https://hub.docker.com/r/factoriotools/factorio/)

> [!注意]
> ARM 架构支持是实验性的。如果你尝试在 Raspberry Pi 上运行，可能会遇到崩溃和延迟问题。

[English](./README.md)

<!-- start autogeneration tags -->
* `2`, `2.0`, `2.0.55`, `latest`, `stable`, `stable-2.0.55`
* `2.0.54`
* `2.0.53`
* `2.0.52`
* `2.0.51`
* `2.0.50`
* `2.0.49`
* `2.0.48`
* `2.0`, `2.0.47`, `stable-2.0.47`
* `2.0.46`
* `2.0.45`
* `2.0.44`
* `2.0`, `2.0.43`, `stable-2.0.43`
* `2.0`, `2.0.42`, `stable-2.0.42`
* `2.0`, `2.0.41`, `stable-2.0.41`
* `2.0.40`
* `2.0`, `2.0.39`, `stable-2.0.39`
* `2.0.38`
* `2.0.37`
* `2.0.36`
* `2.0.35`
* `2.0.34`
* `2.0.33`
* `2.0`, `2.0.32`, `stable-2.0.32`
* `2.0.31`
* `2.0`, `2.0.30`, `stable-2.0.30`
* `2.0.29`
* `2.0`, `2.0.28`, `stable-2.0.28`
* `2.0.27`
* `2.0.26`
* `2.0.25`
* `2.0.24`
* `2.0`, `2.0.23`, `stable-2.0.23`
* `2.0.22`
* `2.0`, `2.0.21`, `stable-2.0.21`
* `2.0`, `2.0.20`, `stable-2.0.20`
* `2.0.19`
* `2.0.18`
* `2.0.17`
* `2.0.16`
* `2.0`, `2.0.15`, `stable-2.0.15`
* `2.0`, `2.0.14`, `stable-2.0.14`
* `2.0`, `2.0.13`, `stable-2.0.13`
* `1`, `1.1`, `1.1.110`, `stable-1.1.110`
* `1.0`, `1.0.0`
* `0.17`, `0.17.79`
* `0.16`, `0.16.51`
* `0.15`, `0.15.40`
* `0.14`, `0.14.23`
* `0.13`, `0.13.20`
* `0.12`, `0.12.35`<!-- end autogeneration tags -->

## 标签描述

* `latest` - 最新版本（可能含有实验性功能）。
* `stable` - 在 [factorio.com](https://www.factorio.com) 上声明为稳定的版本（[FFF-435 自 2.0 版本起，版本首先作为实验版发布，一旦稳定就会被标记为稳定版](https://factorio.com/blog/post/fff-435)）。
* `0.x` - 某个分支上的最新版本。
* `0.x.y` - 具体的版本。
* `0.x-z` - 该版本的增量修复。

## 什么是 Factorio？

[Factorio](https://www.factorio.com) 是一款建造和维护工厂的游戏。

在游戏中，你将挖掘资源、研发科技、建设基础设施、自动化生产并与敌人战斗。发挥你的想象力来设计工厂，将简单的元素组合成巧妙的结构，运用管理技能保持其正常运转，最后保护它不受那些不太喜欢你的生物的侵害。

游戏非常稳定，并为建造大规模工厂进行了优化。你可以创建自己的地图，用 Lua 编写模组，或通过多人游戏与朋友一起游戏。

**注意**：这仅仅是服务端。完整游戏可在 [Factorio.com](https://www.factorio.com)、[Steam](https://store.steampowered.com/app/427520/)、[GOG.com](https://www.gog.com/game/factorio) 和 [Humble Bundle](https://www.humblebundle.com/store/factorio) 获得。

## 使用方法

### 快速开始

运行服务端以创建必要的文件夹结构和配置文件。在这个例子中，数据存储在 `/opt/factorio`。

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

对于 Docker 新手，这里解释一下选项：

* `-d` - 以守护进程方式运行（"分离"模式）。
* `-p` - 暴露端口。
* `-v` - 将本地文件系统的 `/opt/factorio` 挂载到容器中的 `/factorio`。
* `--restart` - 如果服务端崩溃或系统启动时重启服务端。
* `--name` - 将容器命名为 "factorio"（否则它会有一个有趣的随机名称）。

需要 `chown` 命令是因为在 0.16+ 版本中，出于安全原因，我们不再以 root 身份运行游戏服务端，而是以用户 ID 为 845 的 'factorio' 用户身份运行。因此主机必须允许该用户写入这些文件。

检查日志以查看发生了什么：

```shell
docker logs factorio
```

停止服务端：

```shell
docker stop factorio
```

现在在 `/opt/factorio/config` 文件夹中有一个 `server-settings.json` 文件。根据你的喜好修改它并重启服务端：

```shell
docker start factorio
```

尝试连接到服务端。如果无法正常工作，请检查日志。

### 控制台

要向服务端发出控制台命令，请使用 `-it` 以交互模式启动服务端。使用 `docker attach` 打开控制台，然后输入命令。

```shell
docker run -d -it  \
      --name factorio \
      factoriotools/factorio
docker attach factorio
```

### RCON (2.0.18+)

或者（例如用于脚本），可以使用 RCON 连接向正在运行的 factorio 服务端发送命令。
这不需要暴露 RCON 连接。

```shell
docker exec factorio rcon /h
```

### 更新

在升级服务端之前，请备份存档。在客户端中制作存档很容易。

确保在运行服务端时使用了 `-v` 参数，这样存档就在 Docker 容器外部。`docker rm` 命令会完全销毁容器，如果存档没有存储在数据卷中，也会包括存档。

删除容器并刷新镜像：

```shell
docker stop factorio
docker rm factorio
docker pull factoriotools/factorio
```

现在像之前一样运行服务端。大约一分钟后，新版本的 Factorio 应该就会运行起来，完整保留存档和配置！

### 存档

服务端首次启动时会生成一个名为 `_autosave1.zip` 的新地图。使用 `/opt/factorio/config` 中的 `map-gen-settings.json` 和 `map-settings.json` 文件作为地图设置。在后续运行中使用最新的存档。

要加载旧存档，请停止服务端并运行命令 `touch oldsave.zip`。这会重置日期。然后重启服务端。另一个选择是删除除一个存档外的所有存档。

要生成新地图，请停止服务端，删除所有存档并重启服务端。

#### 直接指定存档（0.17.79-2+）

你可以通过一组环境变量配置服务端来指定要加载的特定存档：

要加载现有存档，请将 `SAVE_NAME` 设置为位于 `saves` 目录中的现有存档文件名，不包含 `.zip` 扩展名：

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

要生成新地图，请设置 `GENERATE_NEW_SAVE=true` 并指定 `SAVE_NAME`：

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

### Mods-模组

将模组复制到 mods 文件夹中并重启服务端。

从 0.17 版本开始，添加了一个新的环境变量 `UPDATE_MODS_ON_START`，如果设置为 `true`，将在服务端启动时更新模组。如果设置了此选项，必须提供有效的 [Factorio 用户名和令牌](https://www.factorio.com/profile)，否则服务端将不会启动。它们可以设置为 docker secrets、环境变量，或从 server-settings.json 文件中获取。

### Scenarios-场景

如果你想从全新开始启动场景（而不是从保存的地图），你需要从备用入口点启动 docker 镜像。为此，请使用存储在卷中 /factorio/entrypoints 目录中的示例入口点文件，并使用以下语法启动镜像。请注意，这是正常语法，添加了 --entrypoint 设置和末尾的附加参数，这是 Scenarios 文件夹中场景的名称。

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

### 将场景转换为常规地图

如果你想将场景导出为保存的地图，可以使用类似于上述场景用法的示例入口点。Factorio 将运行一次，将场景转换为 saves 目录中的保存地图。然后使用标准选项重启 docker 镜像将加载该地图，就像上述场景示例刚启动的场景一样。

```shell
docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=unless-stopped  \
  --entrypoint "/scenario2map.sh" \
  factoriotools/factorio
  MyScenarioName
```

### RCON

在 `rconpw` 文件中设置 RCON 密码。如果 `rconpw` 不存在，将生成随机密码。

要更改密码，请停止服务端，修改 `rconpw`，然后重启服务端。

要"禁用" RCON，请不要暴露端口 27015，即不使用 `-p 27015:27015/tcp` 启动服务端。RCON 仍在运行，但没有人可以连接到它。


### 白名单 (0.15.3+)

创建文件 `config/server-whitelist.json` 并添加白名单用户。

```json
[
"you",
"friend"
]
```

### 黑名单 (0.17.1+)

创建文件 `config/server-banlist.json` 并添加黑名单用户。

```json
[
"bad_person",
"other_bad_person"
]
```

### 管理员列表 (0.17.1+)

创建文件 `config/server-adminlist.json` 并添加管理员用户。

```json
[
"you",
"friend"
]
```

### 自定义配置文件 (0.17.x+)

开箱即用的 factorio 不支持配置文件中的环境变量。一个解决方法是使用 `envsubst`，它在启动期间从 docker-compose 中设置的环境变量动态生成配置文件：

替换 server-settings.json 的示例：

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

然后 `server-settings.json` 文件可能包含这样的变量引用：

```json
"name": "${INSTANCE_NAME}",
"description": "${INSTANCE_DESC}",
```

### 环境变量

这些是可以在容器运行时指定的环境变量。

| 变量名               | 描述                                                            | 默认值         | 可用版本     |
|---------------------|----------------------------------------------------------------|----------------|--------------|
| GENERATE_NEW_SAVE   | 如果在启动服务端之前不存在存档，则生成新存档                      | false          | 0.17+        |
| LOAD_LATEST_SAVE    | 为 true 时加载最新存档。否则加载 SAVE_NAME                      | true           | 0.17+        |
| PORT                | 服务端监听的 UDP 端口                                           | 34197          | 0.15+        |
| BIND                | 服务端监听的 IP 地址（v4 或 v6）(IP\[:PORT])                    |                | 0.15+        |
| RCON_PORT           | rcon 服务端监听的 TCP 端口                                       | 27015          | 0.15+        |
| SAVE_NAME           | 存档文件使用的名称                                               | _autosave1     | 0.17+        |
| TOKEN               | factorio.com 令牌                                               |                | 0.17+        |
| UPDATE_MODS_ON_START| 是否在启动服务端之前更新模组                                     |                | 0.17+        |
| USERNAME            | factorio.com 用户名                                             |                | 0.17+        |
| CONSOLE_LOG_LOCATION| 将控制台日志保存到指定位置                                       |                |              |
| DLC_SPACE_AGE       | 在 mod-list.json 中启用或禁用 DLC Space Age 的模组[^1]          | true           | 2.0.8+       |
| MODS                | 要使用的模组目录                                                 | /factorio/mods | 2.0.8+       |

**注意**：所有环境变量都作为字符串进行比较

## 容器细节

理念是[保持简单](http://wiki.c2.com/?KeepItSimple)。

* 服务端应该自启动。
* 优先使用配置文件而不是环境变量。
* 使用一个数据卷。

### 数据卷

为了保持简单，容器使用挂载在 `/factorio` 的单个卷。此卷存储配置、模组和存档。

此卷中的文件应该由 factorio 用户拥有，uid 845。

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

[Docker Compose](https://docs.docker.com/compose/install/) 是运行 Docker 容器的简便方法。

* 需要 docker-engine >= 1.10.0
* 需要 docker-compose >=1.6.0

首先获取一个 [docker-compose.yml](https://github.com/factoriotools/factorio-docker/blob/master/docker/docker-compose.yml) 文件。从此仓库获取：

```shell
git clone https://github.com/factoriotools/factorio-docker.git
cd factorio-docker/docker
```

或者创建你自己的：

```yaml
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

现在 cd 到包含 docker-compose.yml 的目录并运行：

```shell
sudo mkdir -p /opt/factorio
sudo chown 845:845 /opt/factorio
sudo docker-compose up -d
```

### 端口

* `34197/udp` - 游戏服务端（必需）。可以通过 `PORT` 环境变量更改。
* `27015/tcp` - RCON（可选）。

## 局域网游戏

确保 server-settings.json 中的 `lan` 设置为 `true`。

```json
  "visibility":
  {
    "public": false,
    "lan": true
  },
```

使用 `--network=host` 选项启动容器，以便客户端可以自动找到局域网游戏。参考快速入门来创建 `/opt/factorio` 目录。

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

## 部署到其他平台

### Vagrant

[Vagrant](https://www.vagrantup.com/) 是设置虚拟机（VM）运行 Docker 的简便方法。[Factorio Vagrant box 仓库](https://github.com/dtandersen/factorio-lan-vagrant)包含一个示例 Vagrantfile。

对于局域网游戏，VM 需要内部 IP 以便客户端连接。一种方法是使用公共网络。VM 使用 DHCP 获取 IP 地址。VM 还必须转发端口 34197。

```ruby
  config.vm.network "public_network"
  config.vm.network "forwarded_port", guest: 34197, host: 34197
```

### Amazon Web Services (AWS) 部署

如果你正在寻找一种简单的方法将此部署到 Amazon Web Services 云，请查看 [Factorio Server Deployment (CloudFormation) 仓库](https://github.com/m-chandler/factorio-spot-pricing)。此仓库包含一个 CloudFormation 模板，可以让你在几分钟内在 AWS 上运行起来。它可选择使用 Spot Pricing，因此服务端非常便宜，你可以在不使用时轻松关闭它。

## 使用反向代理

如果你需要使用反向代理，可以使用以下 nginx 片段：

```
stream {
  server {
      listen 34197 udp reuseport;
      proxy_pass my.upstream.host:34197;
  }
}
```

如果你的 factorio 主机使用多个 IP 地址（IPv6 非常常见），你可能还需要将 Factorio 绑定到单个 IP（否则 UDP 代理可能会因 IP 不匹配而混乱）。要做到这一点，将 `BIND` 环境变量传递给容器：`docker run --network=host -e BIND=2a02:1234::5678 ...`

## 疑难解答

### 我的服务端在服务端浏览器中列出，但没有人可以连接

检查日志。如果有一行显示 `Own address is RIGHT IP:WRONG PORT`，那么这可能是由 Docker 代理引起的。如果 IP 和端口是正确的，可能是端口转发或防火墙问题。

默认情况下，Docker 通过代理路由流量。代理更改源 UDP 端口，因此检测到错误的端口。有关详细信息，请参阅论坛帖子 *[docker 托管服务端检测到错误端口](https://forums.factorio.com/viewtopic.php?f=49&t=35255)*。

为了修复错误端口，使用 `--userland-proxy=false` 开关启动 Docker 服务。Docker 将使用 iptables 规则而不是代理路由流量。将开关添加到 `DOCKER_OPTS` 环境变量或 Docker systemd 服务定义中的 `ExecStart`。具体情况因操作系统而异。

### 当我在 34197 之外的端口上运行服务端时，没有人可以从服务端浏览器连接

使用 `PORT` 环境变量在不同端口上启动服务端，例如 `docker run -e "PORT=34198"`。这会更改用于端口检测的数据包的源端口。`-p 34198:34197` 对于私人服务端工作正常，但服务端浏览器检测到错误的端口。

## 贡献者

* [dtandersen](https://github.com/dtandersen) - 维护者
* [Fank](https://github.com/Fankserver) - Factorio 监视程序的程序员，保持版本更新。
* [SuperSandro2000](https://github.com/supersandro2000) - CI 负责人，维护者和 Factorio 监视程序的运行者。贡献版本更新并编写了 Travis 脚本。
* [DBendit](https://github.com/DBendit/docker_factorio_server) - 编写了管理员列表、禁止列表支持并贡献版本更新
* [Zopanix](https://github.com/zopanix/docker_factorio_server) - 原作者
* [Rfvgyhn](https://github.com/Rfvgyhn/docker-factorio) - 编写了随机生成的 RCON 密码
* [gnomus](https://github.com/gnomus/docker_factorio_server) - 编写了白名单支持
* [bplein](https://github.com/bplein/docker_factorio_server) - 编写了场景支持
* [jaredledvina](https://github.com/jaredledvina/docker_factorio_server) - 贡献版本更新
* [carlbennett](https://github.com/carlbennett) - 贡献版本更新和错误修复

[^1]: Space Age 模组也可以通过使用它们的名称（用空格分隔）来单独启用。  
  示例 1：使用 `true` 启用所有  
  示例 2：通过列出模组名称启用所有 `space-age elevated-rails quality`  
  示例 3：仅启用 Elevated rails `elevated-rails`
