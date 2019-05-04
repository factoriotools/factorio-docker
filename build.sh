#!/bin/bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: ./build.sh \$VERSION_SHORT"
else
  VERSION_SHORT="$1"
fi

VERSION=$(grep -oP '[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_SHORT/Dockerfile" | head -1)
cd "$VERSION_SHORT" || exit

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  if [ "$TRAVIS_BRANCH" == "master" ]; then
    TAG="$VERSION -t factoriotools/docker_factorio_server:$VERSION_SHORT"
  else
    TAG="$TRAVIS_BRANCH"
  fi

  docker build . -t "factoriotools/docker_factorio_server:$TAG"

  # echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  # docker push "factoriotools/docker_factorio_server:$VERSION"
fi

docker images
