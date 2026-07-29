#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPONENTS=(Base Gz Interface RMF)

usage() {
  cat <<'EOF'
Usage:
  ./build_all.sh [build.sh options]

Description:
  Runs docker/build.sh for Base, Gz, Interface, and RMF in sequence.
  Any arguments are forwarded to each build.sh.

Examples:
  ./build_all.sh
  ./build_all.sh --ros-distro jazzy
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for component in "${COMPONENTS[@]}"; do
  script_path="$ROOT_DIR/$component/docker/build.sh"

  if [[ ! -f "$script_path" ]]; then
    echo "Missing script: $script_path"
    exit 1
  fi

  echo ""
  echo "=== Building $component ==="
  bash "$script_path" "$@"
  echo "=== Finished $component ==="
done

echo ""
echo "All builds completed successfully."
