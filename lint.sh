#!/bin/bash
git ls-files --exclude='*Dockerfile' --ignored | xargs --max-lines=1 ./hadolint
