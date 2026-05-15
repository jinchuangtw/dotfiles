#!/bin/bash
set -e

source /opt/ros/noetic/setup.bash

if [ -f /home/developer/catkin_ws/devel/setup.bash ]; then
    source /home/developer/catkin_ws/devel/setup.bash
fi

exec "$@"
