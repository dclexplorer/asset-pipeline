#!/bin/bash

# Remove stack from Docker Swarm
set -e

echo "Removing Godot Server Pipeline from Docker Swarm..."

# Remove stack
docker stack rm godot-pipeline

echo "Stack 'godot-pipeline' removed successfully!"
echo ""
echo "To check if all services are removed:"
echo "docker stack ls"
echo "docker service ls"