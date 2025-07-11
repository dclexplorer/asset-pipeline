#!/bin/bash

# Deploy to Docker Swarm
set -e

echo "Deploying Godot Server Pipeline to Docker Swarm..."

# Check if Docker Swarm is initialized
if ! docker info | grep -q "Swarm: active"; then
    echo "Docker Swarm is not initialized. Initializing..."
    docker swarm init
fi

# Validate environment variables
echo "Validating environment variables..."
./scripts/validate-env.sh

# Build images first
echo "Building Docker images..."
./scripts/build-images.sh

# Deploy stack
echo "Deploying stack to Docker Swarm..."
docker stack deploy -c docker-stack.yml godot-pipeline

echo ""
echo "Waiting for services to start..."
sleep 30

# Check deployment status
echo "Checking deployment status..."
docker stack ps godot-pipeline

echo ""
echo "Deployment completed!"
echo ""
echo "Stack deployed as 'godot-pipeline'"
echo "Services deployed:"
echo "- godot-pipeline_consumer-processor-optimizer (6 replicas)"
echo "- godot-pipeline_entity-queue-producer (1 replica)"
echo "- godot-pipeline_status-service (1 replica)"
echo ""
echo "Service endpoints:"
echo "- Entity Queue Producer: http://localhost:${ENTITY_QUEUE_PORT:-8081}"
echo "- Status Service: http://localhost:${STATUS_SERVICE_PORT:-8082}"
echo ""
echo "Useful commands:"
echo "- Check service status: docker stack ps godot-pipeline"
echo "- View service logs: docker service logs godot-pipeline_<service-name>"
echo "- Remove stack: docker stack rm godot-pipeline"