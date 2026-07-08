# VS Code + WSL + Docker Container Workflow

This guide explains how to create and manage a Docker container from WSL, mount a Windows workspace into the container, connect VS Code to the running container, and rebuild Docker images after Dockerfile changes.

---

# 1. Start WSL and Docker

## Open WSL Ubuntu 24.04

Start Ubuntu from Windows:

* Windows Start Menu → **Ubuntu 24.04**
* Or from PowerShell / Command Prompt:

```bash
wsl
```

Make sure Docker is running inside WSL.

Check Docker:

```bash
docker --version
```

---

# 2. Manage Existing Containers

## List running containers

```bash
docker ps
```

## List all containers

```bash
docker ps -a
```

## Start an existing container

If the container already exists but is stopped:

```bash
docker start mycontainer
```

Check status:

```bash
docker ps
```

---

# 3. Create a New Container with a Windows Workspace Mounted

Example Windows workspace:

```
C:\Users\Fabian\OneDrive - Berner Fachhochschule\Desktop\Masterproject\20_ROS
```

Inside WSL, Windows drives are available under `/mnt`.

The path becomes:

```
/mnt/c/Users/Fabian/OneDrive - Berner Fachhochschule/Desktop/Masterproject/20_ROS
```

Create the container:

```bash
docker run -d \
  --name mycontainer \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "/mnt/c/Users/Fabian/OneDrive - Berner Fachhochschule/Desktop/Masterproject/20_ROS:/ros2_ws" \
  starrynight:latest \
  tail -f /dev/null
```

Explanation:

| Option                             | Purpose                           |
| ---------------------------------- | --------------------------------- |
| `--name mycontainer`               | Container name                    |
| `-e DISPLAY=$DISPLAY`              | Enables graphical applications    |
| `-v /tmp/.X11-unix:/tmp/.X11-unix` | Enables X11 display forwarding    |
| `-v host:container`                | Mounts Windows folder into Docker |
| `tail -f /dev/null`                | Keeps container running           |

The Windows workspace is now available inside Docker:

```
/ros2_ws
```

---

# 4. Enter the Running Container

Open a terminal inside the container:

```bash
docker exec -it mycontainer bash
```

You are now working inside the Docker environment.

Check:

```bash
pwd
```

---

# 5. Verify the Workspace Mount

Inside the container:

```bash
ls -la /ros2_ws
```

Your Windows files should appear.

If the folder is empty, check the mount:

```bash
docker inspect mycontainer
```

The mount should contain:

```
/mnt/c/Users/Fabian/.../20_ROS -> /ros2_ws
```

---

# 6. Connect VS Code to the Container

Install the following VS Code extensions:

* **Remote - WSL**
* **Dev Containers**

## Attach VS Code to the container

1. Open VS Code
2. Press:

```
Ctrl + Shift + P
```

3. Select:

```
Dev Containers: Attach to Running Container
```

4. Select:

```
mycontainer
```

5. Open the workspace:

```
/ros2_ws
```

VS Code is now running inside the Docker environment while editing the Windows files.

---

# 7. Check Docker Mounts

From WSL:

```bash
docker inspect mycontainer \
-f '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```

Example output:

```
/mnt/c/Users/Fabian/.../20_ROS -> /ros2_ws
```

---

# 8. Container Troubleshooting

## Container name already exists

Remove the existing container:

```bash
docker rm mycontainer
```

If it is running:

```bash
docker stop mycontainer
docker rm mycontainer
```

Then create it again.

---

## Container stops immediately

Containers stop when their main process exits.

Use a keep-alive command:

```bash
tail -f /dev/null
```

Example:

```bash
docker run -d \
  --name mycontainer \
  starrynight:latest \
  tail -f /dev/null
```

---

## Workspace is empty

Check:

1. The Windows path exists.
2. The `/mnt/c/...` path is correct.
3. The container mount is correct:

```bash
docker inspect mycontainer
```

The destination should match the folder opened in VS Code:

```
/ros2_ws
```

---

# 9. Modify the Dockerfile

Navigate to the folder containing the Dockerfile:

```bash
cd ~/workspace
```

Or open it directly:

```bash
code Dockerfile
```

Example Dockerfile:

```dockerfile
FROM ubuntu:24.04

RUN apt update && apt install -y \
    python3 \
    python3-pip \
    bash

WORKDIR /ros2_ws

CMD ["bash"]
```

Edit the Dockerfile as required and save.

---

# 10. Build a New Docker Image

Build the image:

```bash
docker build -t starrynight:new .
```

Check available images:

```bash
docker images
```

Example:

```
REPOSITORY      TAG       IMAGE ID
starrynight     new       abc123456
```

---

# 11. Create a Container from the New Image

Remove the old container:

```bash
docker stop mycontainer
docker rm mycontainer
```

Create a new container:

```bash
docker run -d \
  --name mycontainer \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "/mnt/c/Users/Fabian/OneDrive - Berner Fachhochschule/Desktop/Masterproject/20_ROS:/ros2_ws" \
  starrynight:new \
  tail -f /dev/null
```

---

# 12. Rebuild After Dockerfile Changes

After modifying the Dockerfile:

```bash
docker build --no-cache -t starrynight:new .
```

`--no-cache` forces Docker to execute every build step again.

---

# 13. Version Docker Images

Create a version tag:

```bash
docker tag starrynight:new starrynight:v1.0
```

List images:

```bash
docker images
```

Example:

```
REPOSITORY      TAG
starrynight     new
starrynight     v1.0
```

---

# 14. Remove Docker Images and Clean Up

List images:

```bash
docker images
```

Remove an image:

```bash
docker rmi <image_id>
```

Remove unused Docker resources:

```bash
docker system prune
```

---

# Typical Daily Workflow

## Start working

```bash
wsl
docker start mycontainer
```

Open VS Code:

```
Dev Containers → Attach to Running Container → mycontainer
```

Open:

```
/ros2_ws
```

---

## After changing the Dockerfile

```bash
docker build -t starrynight:new .
docker stop mycontainer
docker rm mycontainer
docker run -d ... starrynight:new tail -f /dev/null
```

Then reconnect VS Code.
