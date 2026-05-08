FROM osrf/ros:noetic-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Basic tools + ROS build tools + common GVINS dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    vim \
    nano \
    gdb \
    python3-pip \
    python3-catkin-tools \
    python3-rosdep \
    python3-vcstool \
    python3-osrf-pycommon \
    ros-noetic-cv-bridge \
    ros-noetic-image-transport \
    ros-noetic-image-transport-plugins \
    ros-noetic-tf \
    ros-noetic-tf2 \
    ros-noetic-tf2-ros \
    ros-noetic-tf2-geometry-msgs \
    ros-noetic-pcl-ros \
    ros-noetic-pcl-conversions \
    ros-noetic-eigen-conversions \
    ros-noetic-rviz \
    ros-noetic-rqt \
    ros-noetic-rqt-graph \
    ros-noetic-rosbag \
    ros-noetic-rosbag-storage \
    libeigen3-dev \
    libceres-dev \
    libsuitesparse-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libopencv-dev \
    libyaml-cpp-dev \
    libboost-all-dev \
    libpcl-dev \
    libgeographic-dev \
    geographiclib-tools \
    && rm -rf /var/lib/apt/lists/*

# GeographicLib datasets, 常見 GNSS/VINS 專案會需要
RUN geographiclib-get-geoids egm96-5 || true

# 建立一個和 host user UID/GID 對齊的使用者，避免 build 出來的檔案都變 root
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} || true && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash || true && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/${USERNAME}/catkin_ws

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ${USERNAME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
