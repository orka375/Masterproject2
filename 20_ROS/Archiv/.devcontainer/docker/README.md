### Docker

#### Prerequisites

It is a requirement to have `docker engine` already installed in the host machine.

* See [Docker Installation Guide](https://docs.docker.com/engine/install/ubuntu/)

For NVIDIA GPU support, `nvidia-container-toolkit` should be installed. *Skip this step if you don't have an NVIDIA graphics card*


* Make sure you have the drivers installed:
  ```sh
  nvidia-smi
  ```
* See [NVIDIA Container Toolkit Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

#### Building image and running container

- Build the docker image whose default name is `ros2_noble_eta_fleet`:

```sh
./docker/build.sh
```

You can also try to set a specific image name:

```sh
./docker/build.sh -i my_fancy_image_name
```

- Run or attach to a docker container from `ros2_noble_eta_fleet` called `ros2_noble_eta_fleet_container`:

```sh
./docker/run.sh
```

If the container already exists, the script starts it (if needed) and attaches a shell.
If it does not exist, it creates it and keeps it alive.

- **IMPORTANT**: If you are using nvidia drivers add the `--use_nvidia` flag:

```sh
./docker/run.sh --use_nvidia
```

You can also try to set specific image and container names:

```sh
./docker/run.sh --use_nvidia -i my_fancy_image_name -c my_fancy_container_name
```

- Inside the container, install dependencies via `rosdep`:

  ```sh
  rosdep install -i -y --rosdistro kilted --from-paths src
  ```

This setup is GitHub-centric: clone or pull your repositories directly inside
the container workspace.

- To build:

  ```sh
  colcon build
  ```
