#!/bin/bash

# Build Docker images for deployment services
set -e

echo "Building Docker images for Godot Server Pipeline..."

# Check environment variables
./scripts/validate-env.sh

# Build consumer-processor Godot optimizer (main deployment service)
echo "Building consumer-processor-optimizer..."

# Detect host architecture for multi-platform builds
HOST_ARCH=$(uname -m)
if [[ "$HOST_ARCH" == "arm64" || "$HOST_ARCH" == "aarch64" ]]; then
    DOCKER_PLATFORM="--platform linux/arm64"
    echo "Detected ARM64 architecture, building for linux/arm64"
else
    DOCKER_PLATFORM="--platform linux/amd64"
    echo "Detected x86_64 architecture, building for linux/amd64"
fi

docker buildx build $DOCKER_PLATFORM -t godot-pipeline/consumer-processor-optimizer:latest \
  --build-arg COMMIT_HASH="${COMMIT_HASH:-$(git rev-parse HEAD)}" \
  --build-arg CURRENT_VERSION="${CURRENT_VERSION:-$(git describe --tags --always)}" \
  -f ./services/consumer-processor/dependencies/godot-asset-optimizer-project/Dockerfile \
  --load \
  ./services/consumer-processor/

# Build entity-queue-producer
echo "Building entity-queue-producer..."
docker build -t godot-pipeline/entity-queue-producer:latest ./services/entity-queue-producer/

# Build status-service
echo "Building status-service..."
docker build -t godot-pipeline/status-service:latest ./services/status-service/

echo "All Docker images built successfully!"
echo ""
echo "Images built for deployment:"
echo "- godot-pipeline/consumer-processor-optimizer:latest (6 replicas)"
echo "- godot-pipeline/entity-queue-producer:latest (1 replica)"
echo "- godot-pipeline/status-service:latest (1 replica)"