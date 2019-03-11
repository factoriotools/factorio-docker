#!/bin/sh -x
if [ -z "$1" ]
  then
    echo "No argument supplied"
fi
SCENARIO=$1

sh /initConfig.sh

exec /opt/factorio/bin/x64/factorio \
  --scenario2map $SCENARIO
