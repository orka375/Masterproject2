FROM osrf/ros:kilted-desktop-full-noble

ARG USERID=1000
ARG USER=rosdev

ENV TERM=linux
ENV DEBIAN_FRONTEND=noninteractive

# Core tooling + ROS 2 Kilted stack used by this repository.
RUN apt-get update && apt-get install --no-install-recommends -y \
    apt-utils \
    bash-completion \
    build-essential \
    cmake \
    curl \
    gdb \
    git \
    gnupg \
    lsb-release \
    nano \
    openssh-client \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-yaml \
    sudo \
    tmux \
    wget \
    ros-kilted-rmf-dev \
    ros-kilted-ros-gz \
    ros-kilted-ros-gz-bridge \
    ros-kilted-nav2-bringup \
    ros-kilted-navigation2 \
    ros-kilted-rqt \
    ros-kilted-rqt-common-plugins \
    ros-kilted-ros2-control \
    ros-kilted-ros2-controllers \
    ros-kilted-robot-state-publisher \
    ros-kilted-joint-state-publisher \
    ros-kilted-joint-state-publisher-gui \
    ros-kilted-xacro \
    ros-kilted-tf-transformations \
    ros-kilted-tf2-tools \
    python3-numpy \
    python3-opencv \
    && rm -rf /var/lib/apt/lists/*

# Install Gazebo Jetty from OSRF packages.
RUN curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
      -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/gazebo-stable.list && \
    apt-get update && apt-get install --no-install-recommends -y gz-jetty && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root developer user with passwordless sudo.
RUN adduser --uid ${USERID} --gecos "ros developer" --disabled-password ${USER} && \
    adduser ${USER} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN rosdep init || true && rosdep update

RUN pip3 install --no-cache-dir nudged transforms3d

RUN mkdir -p /ros2_ws/src && chown -R ${USER}:${USER} /ros2_ws

RUN echo "source /opt/ros/kilted/setup.bash" >> /etc/bash.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /etc/bash.bashrc && \
    echo "source /ros2_ws/install/setup.bash 2>/dev/null || true" >> /etc/bash.bashrc

USER ${USER}
WORKDIR /ros2_ws

CMD ["/bin/bash"]