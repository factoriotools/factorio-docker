#!/bin/bash
set -eo pipefail

if [ -z "$1" ] ; then
  echo "Usage: ./build.sh \$VERSION"
else
  VERSION="$1"
fi

cd "$VERSION" || exit

docker build . -t "factoriotools/docker_factorio_server:$VERSION"
