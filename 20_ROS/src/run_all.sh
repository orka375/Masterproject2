#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPONENTS=(Base Gz Interface RMF)

usage() {
  cat <<'EOF'
Usage:
  ./run_all.sh [run.sh options]

Description:
  Runs docker/run.sh for Base, Gz, Interface, and RMF in sequence.
  Any arguments are forwarded to each run.sh.

Notes:
  - Existing default containers are removed before each launch.
  - Do not pass -c/--container_name; run_all.sh manages per-component names.

Examples:
  ./run_all.sh
  ./run_all.sh --ros_distro jazzy
  ./run_all.sh --use_nvidia
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROS_DISTRO="kilted"
for ((i=1; i<=$#; i++)); do
  arg="${!i}"
  if [[ "$arg" == "-d" || "$arg" == "--ros_distro" ]]; then
    next_index=$((i + 1))
    if (( next_index <= $# )); then
      ROS_DISTRO="${!next_index}"
    fi
  fi
  if [[ "$arg" == "-c" || "$arg" == "--container_name" ]]; then
    echo "run_all.sh does not support -c/--container_name because each component has its own container name."
    exit 1
  fi
done

for component in "${COMPONENTS[@]}"; do
  script_path="$ROOT_DIR/$component/docker/run.sh"
  component_lc="$(echo "$component" | tr '[:upper:]' '[:lower:]')"
  container_name="ros2_${ROS_DISTRO}_eta_${component_lc}_container"

  if [[ ! -f "$script_path" ]]; then
    echo "Missing script: $script_path"
    exit 1
  fi

  if sudo docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
    echo "Removing existing container: $container_name"
    sudo docker rm -f "$container_name" >/dev/null
  fi

  echo ""
  echo "=== Running $component ==="
  bash "$script_path" "$@"
  echo "=== Started $component ==="
done

echo ""
echo "All run scripts completed."
