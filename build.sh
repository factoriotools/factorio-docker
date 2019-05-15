#!/bin/bash
set -eox pipefail

if [ -z "$1" ]; then
  echo "Usage: ./build.sh \$VERSION_SHORT"
else
  VERSION_SHORT="$1"
fi

VERSION=$(grep -oP '[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_SHORT/Dockerfile" | head -1)
DOCKER_REPO=factoriotools/docker_factorio_server
cd "$VERSION_SHORT" || exit

if [ "$TRAVIS_PULL_REQUEST" == "true" ]; then
  TAG="$TRAVIS_PULL_REQUEST_SLUG"
else
  if [ "$TRAVIS_BRANCH" == "master" ]; then
    TAG="$VERSION -t $DOCKER_REPO:$VERSION_SHORT"
  else
    TAG="$TRAVIS_BRANCH"
  fi

  if [ -n "$EXTRA_TAG" ]; then
    TAG="$TAG -t $DOCKER_REPO:$EXTRA_TAG"
  fi
fi

# shellcheck disable=SC2086
docker build . -t $DOCKER_REPO:$TAG

docker images

if [ "$(dirname "$(git diff --name-only HEAD^)" | head -1)" == "$VERSION" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
  # echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push "$DOCKER_REPO:latest"

  if [ -n "$EXTRA_TAG" ]; then
    docker push "$DOCKER_REPO:$EXTRA_TAG"
  fi

  if [ -n "$TRAVIS_TAG" ]; then
    docker push "$DOCKER_REPO:$VERSION"
    docker push "$DOCKER_REPO:$VERSION_SHORT"
  fi

  curl -X POST https://hooks.microbadger.com/images/factoriotools/factorio/TmmKGNp8jKcFqZvcJhTCIAJVluw=
fi
