#!/bin/sh
sudo docker run --rm -it \
	-v /tmp/factorio:/factorio \
	--name factorio \
	factorio "$@"
find /tmp/factorio -type f
