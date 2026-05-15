#!/bin/bash
set -e

cd ~/Development/catkin_ws_docker/docker

xhost +local:docker >/dev/null 2>&1 || true

HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose run --rm gvins-dev bash -lc "
cd /home/developer/catkin_ws
catkin_make
"
