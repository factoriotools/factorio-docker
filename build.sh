#!/bin/bash
set -eoux pipefail

if [[ -z ${1:-} ]] && [[ -n ${CI:-} ]]; then
  echo 'Usage: ./build.sh VERSION_SHORT'
  exit 1
elif [[ ${CI:-} == true ]] || [[ -n ${1:-} ]]; then
  VERSION_SHORT="$1"
else
  VERSION_SHORT=$(find . -maxdepth 1 -type d | sort | tail -1 | grep -o "[[0-9]].[[0-9]]*")
  EXTRA_TAG=latest
fi

cd "$VERSION_SHORT" || exit 1

VERSION=$(grep -oP '[0-9]+\.[0-9]+\.[0-9]+' Dockerfile | head -1)
DOCKER_REPO=factoriotools/factorio

if [[ ${TRAVIS_PULL_REQUEST:-} == true ]]; then
  TAGS="$DOCKER_REPO:$TRAVIS_PULL_REQUEST_SLUG"
else
  if [[ -n ${CI:-} ]]; then
    # we are either on master or on a tag build
    if [[ $TRAVIS_BRANCH == master ]] || [[ $TRAVIS_BRANCH == "$VERSION" ]]; then
      TAGS="-t $DOCKER_REPO:$VERSION -t $DOCKER_REPO:$VERSION_SHORT"
    # we are on an incremental build of a tag
    elif [[ $VERSION == "${TRAVIS_BRANCH%-*}" ]]; then
      TAGS="-t $DOCKER_REPO:$TRAVIS_BRANCH -t $DOCKER_REPO:$VERSION -t $DOCKER_REPO:$VERSION_SHORT"
    # we build a other branch than master
    # disabled for now cause it breaks Travis CI builds of dependabot
    # https://travis-ci.org/github/factoriotools/factorio-docker/jobs/688176474#L182
    # elif [[ -n $TRAVIS_BRANCH ]]; then
    #   TAGS="-t $DOCKER_REPO:$TRAVIS_BRANCH"
    fi
  else
    # we are not in CI and tag version and version short
    TAGS="-t $DOCKER_REPO:$VERSION -t $DOCKER_REPO:$VERSION_SHORT"
  fi

  if [[ -n ${EXTRA_TAG:-} ]]; then
    IFS=","
    for TAG in $EXTRA_TAG; do
      TAGS+=" -t $DOCKER_REPO:$TAG"
    done
  fi

  if [[ ${STABLE:-} == "$VERSION" ]]; then
    TAGS+=" -t $DOCKER_REPO:stable"
  fi
fi

# shellcheck disable=SC2068
eval docker build . ${TAGS[@]}
docker images

if [[ ${TRAVIS_BRANCH:-} ]]; then
  TRAVIS_BRANCH_VERSION=${TRAVIS_BRANCH%-*}
fi

# only push when:
# latest changes where made in the folder corosponding to the version we build, we are on master and don#t build a PR.
if [[ $(dirname "$(git diff --name-only HEAD^)") =~ $VERSION_SHORT ]] && [[ ${TRAVIS_BRANCH:-} == master ]] && [[ $TRAVIS_PULL_REQUEST_BRANCH == "" ]] ||
  # we build a tag and we are not on master
  [[ $VERSION == "${TRAVIS_BRANCH_VERSION:-}" ]] && [[ ${TRAVIS_PULL_REQUEST_BRANCH:-} == "" ]] ||
  # we are not in CI
  [[ -z ${CI:-} ]]; then

  if [[ ${CI:-} == true ]]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  fi

  # push a tag on a branch other than master
  if [[ -n ${TRAVIS_BRANCH:-} ]] && [[ $VERSION != "${TRAVIS_BRANCH_VERSION:-}" ]] && [[ ${TRAVIS_BRANCH:-} != "master" ]]; then
    docker push "$DOCKER_REPO:$TRAVIS_BRANCH"
  fi

  # push an incremental tag
  if [[ $VERSION == "${TRAVIS_BRANCH_VERSION:-}" ]]; then
    docker push "$DOCKER_REPO:$TRAVIS_BRANCH"
  fi

  if [[ -n ${TRAVIS_TAG:-} ]] || [[ -z ${CI:-} ]]; then
    docker push "$DOCKER_REPO:$VERSION"
    docker push "$DOCKER_REPO:$VERSION_SHORT"
  fi

  if [[ -n ${EXTRA_TAG:-} ]]; then
    IFS=","
    for TAG in $EXTRA_TAG; do
      docker push "$DOCKER_REPO:$TAG"
    done
  fi

  if [[ ${STABLE:-} == "$VERSION" ]]; then
    docker push "$DOCKER_REPO:stable"
  fi

  curl -X POST https://hooks.microbadger.com/images/factoriotools/factorio/TmmKGNp8jKcFqZvcJhTCIAJVluw=
fi
