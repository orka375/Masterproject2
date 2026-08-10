#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "docker-compose.yml not found at $COMPOSE_FILE"
  exit 1
fi

# Keep service and container mapping in one place.
SERVICES=(interface base rmf gz db db_gui)
CONTAINERS=(
  ros2_kilted_eta_interface_container
  ros2_kilted_eta_base_container
  ros2_kilted_eta_rmf_container
  ros2_kilted_eta_gz_container
  postgres_db_container
  postgres_db_gui_container
)

MISSING_SERVICES=()

for i in "${!SERVICES[@]}"; do
  service="${SERVICES[$i]}"
  container="${CONTAINERS[$i]}"

  if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
    if docker ps --format '{{.Names}}' | grep -qx "$container"; then
      echo "Already running: $container"
    else
      echo "Starting existing: $container"
      docker start "$container" >/dev/null

      if ! docker ps --format '{{.Names}}' | grep -qx "$container"; then
        echo "Container exited right after start, will recreate via Compose: $container"
        docker rm -f "$container" >/dev/null 2>&1 || true
        MISSING_SERVICES+=("$service")
      fi
    fi
  else
    echo "Missing container for service '$service': $container"
    MISSING_SERVICES+=("$service")
  fi
done

if [[ ${#MISSING_SERVICES[@]} -gt 0 ]]; then
  echo "Creating and starting missing services via Compose: ${MISSING_SERVICES[*]}"
  docker compose -f "$COMPOSE_FILE" up -d "${MISSING_SERVICES[@]}"
else
  echo "All containers already exist and are running."
fi
