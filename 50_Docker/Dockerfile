# Base image and build arguments
ARG ROS_DISTRO=kilted
FROM osrf/ros:${ROS_DISTRO}-desktop-full

ARG USERID=1000
ARG USER=admin
ARG ROS_DISTRO

######################
# 1) Environment
######################
ENV TERM=linux
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

######################
# 2) Install
######################
# Install base OS dependencies from project requirements.
COPY docker/requirements.txt .
RUN apt-get update && apt-get install --no-install-recommends -y $(cat requirements.txt)
RUN rm requirements.txt

# Install ROS-related apt dependencies from project requirements.
COPY docker/ros_requirements.txt .
RUN apt-get update && apt-get install --no-install-recommends -y $(sed "s/\${ROS_DISTRO}/${ROS_DISTRO}/g" ros_requirements.txt | grep -v '^#' | grep -v '^$')
RUN rm ros_requirements.txt

# Create default runtime user with passwordless sudo.
RUN adduser --gecos "admin" --disabled-password $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $USER

# Enable access to serial and USB device groups.
RUN sudo usermod -a -G dialout $USER
RUN sudo usermod -a -G plugdev $USER

######################
# 3) Update
######################
RUN sudo apt upgrade -y && sudo apt update && rosdep update

######################
# 4) Git Clone
######################
RUN mkdir -p /home/$USER/ros_ws/src /home/$USER/ros_ws/build /home/$USER/ros_ws/install /home/$USER/ros_ws/log
WORKDIR /home/$USER/ros_ws/src

RUN git clone https://github.com/orka375/eta_base.git

WORKDIR /home/$USER/ros_ws
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release --build-base /home/$USER/ros_ws/build --install-base /home/$USER/ros_ws/install --log-base /home/$USER/ros_ws/log

######################
# 5) Bashrc Setup
######################
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/$USER/.bashrc
RUN echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /home/$USER/.bashrc
RUN echo "export ROS_DOMAIN_ID=1" >> /home/$USER/.bashrc
RUN echo "export QT_X11_NO_MITSHM=1" >> /home/$USER/.bashrc

######################
# 6) Pip
######################
# No additional pip packages are required in this image.

######################
# 7) Workspace
######################
RUN mkdir -p /home/$USER/ws/src
WORKDIR /home/$USER/ws

CMD ["/bin/bash"]
