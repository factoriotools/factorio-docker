#!/bin/bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: ./build.sh \$VERSION"
else
  VERSION="$1"
fi

cd "$VERSION" || exit

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  if [ "$TRAVIS_BRANCH" == "master" ]; then
    TAG="$VERSION"
  else
    TAG="$TRAVIS_BRANCH"
  fi
fi

docker build . -t "factoriotools/docker_factorio_server:$TAG"
