#!/bin/bash

# BSD 3-Clause License
#
# Copyright (c) 2024, Ekumen Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e

# Prints information about usage.
function show_help() {
  echo $'\nUsage:\t run.sh [OPTIONS]\n
  Options:\n
  	-i --image_name\t\t Name of the image to run (default ros2_noble_eta_fleet).\n
  	-c --container_name\t Name of the container (default ros2_noble_eta_fleet_container).\n
  	--use_nvidia\t\t Enable NVIDIA runtime flags.\n
  	-d --detach\t\t Start in detached mode and keep running with tail -f /dev/null.\n
  	--no-attach\t\t Do not open an interactive shell after starting/attaching.\n
  	-h --help\t\t Show this help message.\n
  Examples:\n
  	./docker/run.sh\n
  	./docker/run.sh --use_nvidia\n
  	./docker/run.sh --detach\n'
}

echo "Preparing Docker container..."

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--image_name) IMAGE_NAME="${2}"; shift ;;
        -c|--container_name) CONTAINER_NAME="${2}"; shift ;;
    -d|--detach) DETACH_MODE=1 ;;
    --no-attach) NO_ATTACH=1 ;;
        -h|--help) show_help ; exit 1 ;;
        --use_nvidia) NVIDIA_FLAGS="--gpus=all -e NVIDIA_DRIVER_CAPABILITIES=all" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Update the arguments to default values if needed.

IMAGE_NAME=${IMAGE_NAME:-ros2_noble_eta_fleet}
CONTAINER_NAME=${CONTAINER_NAME:-ros2_noble_eta_fleet_container}
DETACH_MODE=${DETACH_MODE:-0}
NO_ATTACH=${NO_ATTACH:-0}

if [[ "$DETACH_MODE" -eq 1 ]]; then
  NO_ATTACH=1
fi

SSH_PATH="/home/$USER/.ssh"
SSH_AUTH_SOCK_USER="$SSH_AUTH_SOCK"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not in PATH."
  exit 1
fi

CONTAINER_EXISTS=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}')

if [[ -n "$CONTAINER_EXISTS" ]]; then
  if [[ -z "$(docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}')" ]]; then
    echo "Starting existing container: $CONTAINER_NAME"
    docker start "$CONTAINER_NAME" >/dev/null
  else
    echo "Container already running: $CONTAINER_NAME"
  fi
else
  echo "Creating new container: $CONTAINER_NAME"
  RUN_FLAGS=(
    -d
    --privileged
    --net=host
    --ipc=host
    --pid=host
    -e DISPLAY="$DISPLAY"
    -e QT_X11_NO_MITSHM=1
    -v /tmp/.X11-unix:/tmp/.X11-unix
    --name "$CONTAINER_NAME"
  )

  if [[ -n "$SSH_AUTH_SOCK_USER" ]]; then
    RUN_FLAGS+=(
      -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK_USER"
      -v "$(dirname "$SSH_AUTH_SOCK_USER"):$(dirname "$SSH_AUTH_SOCK_USER")"
    )
  fi

  if [[ -d "$SSH_PATH" ]]; then
    RUN_FLAGS+=(-v "$SSH_PATH:$SSH_PATH")
  fi

  if [[ -n "$NVIDIA_FLAGS" ]]; then
    # shellcheck disable=SC2206
    NVIDIA_FLAG_ARRAY=($NVIDIA_FLAGS)
    RUN_FLAGS+=("${NVIDIA_FLAG_ARRAY[@]}")
  fi

  KEEP_ALIVE_CMD=(tail -f /dev/null)

  xhost +local:docker >/dev/null 2>&1 || true
  docker run "${RUN_FLAGS[@]}" "$IMAGE_NAME" "${KEEP_ALIVE_CMD[@]}"
  xhost -local:docker >/dev/null 2>&1 || true
fi

if [[ "$NO_ATTACH" -eq 0 ]]; then
  echo "Attaching shell to container..."
  docker exec -it "$CONTAINER_NAME" bash
fi
