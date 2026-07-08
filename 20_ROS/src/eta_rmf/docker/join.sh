#!/bin/bash

CONTAINER_NAME="eta_fleet_container"
echo "Using Container Name: $CONTAINER_NAME"
docker exec -it "$CONTAINER_NAME" bash
