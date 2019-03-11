#!/bin/sh -x
if [ -z "$1" ]
  then
    echo "No argument supplied"
fi
SCENARIO=$1

sh /initConfig.sh

sh /startFactorio.sh "start-server-load-scenario $SCENARIO"
