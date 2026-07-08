# eta Navigation

We rely on [Nav2](https://github.com/ros-planning/navigation2) stack in order to navigate eta.

# Usage

## Prerequisites
  1. Run the mobility stack in a real eta robot or a simulated one:

_Real robot_
```
ros2 launch eta_bringup eta_robot.launch.py
```

_Example with Gazebo Sim_
All the simulation engines supported by eta live in other repositories (check the `related projects` section on main README)
```
ros2 launch eta_gz eta_gz.launch.py
```

  1. Provide a recorded map. Refer to [eta_slam](../eta_slam/README.md) to learn how to record a map with eta.

## Run Nav Stack

```sh
ros2 launch eta_navigation bringup.launch.py map:=<path-to-my-map-yaml-file>
```

By default, the appropriate config file is automatically selected based on the ROS 2 distro (`$ROS_DISTRO`):
- Humble: [nav2_params_humble.yaml](params/nav2_params_humble.yaml)
- Jazzy: [nav2_params_jazzy.yaml](params/nav2_params_jazzy.yaml)

For using a custom param file use:

```sh
ros2 launch eta_navigation bringup.launch.py map:=<path-to-my-map-yaml-file> params_file:=<path-to-my-param-file>
```
