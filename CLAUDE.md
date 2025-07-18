# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a monorepo for Decentraland's Godot-based asset processing pipeline. It contains microservices that handle processing of Godot-based content within Decentraland's infrastructure.

## Key Architecture Components

### Services Structure
- **consumer-processor**: Main processing service with multiple execution modes (HTTP server on port 8080)
  - CRDT Runner: Processes Conflict-free Replicated Data Type operations
  - Godot Optimizer: Optimizes Godot assets (main production service, runs 6 replicas)
  - Godot Runner: Executes Godot explorer
- **entity-queue-producer**: Queue management service (port 8081)
- **status-service**: Health monitoring service (port 8082)

### Technology Stack
- TypeScript/Node.js (v18+)
- Docker & Docker Compose for local development
- Docker Swarm for production deployment
- AWS services (S3 for asset storage, SQS for queues, SNS for notifications)
- Godot game engine for asset processing
- Yarn workspaces for monorepo management

## Essential Development Commands

### Build and Test
```bash
# Build all services
yarn build

# Run all tests
yarn test

# Test specific service
yarn workspace consumer-processor test
yarn workspace entity-queue-producer test

# Lint check/fix
yarn lint:check
yarn lint:fix
```

### Local Development

#### Using dev.sh (Recommended for individual service development)
```bash
# Run the main production service (consumer-processor-optimizer)
./dev.sh consumer-processor-optimizer --build

# Run with custom port
./dev.sh entity-queue-producer --port 8090 --build

# Run in detached mode with logs
./dev.sh consumer-processor-optimizer --detach --logs

# Open shell in service for debugging
./dev.sh consumer-processor-optimizer --shell
```

#### Using dev-helper.sh shortcuts
```bash
# Initial setup
./dev-helper.sh setup

# View running services
./dev-helper.sh ps

# View logs
./dev-helper.sh logs consumer-processor-optimizer

# Stop all services
./dev-helper.sh stop-all

# Run tests for specific service
./dev-helper.sh test consumer-processor

# Clean Docker resources
./dev-helper.sh clean
```

#### Using Docker Compose (all services)
```bash
# Start all services
docker-compose up

# With rebuild
docker-compose up --build
```

### Production Deployment
```bash
# Deploy to Docker Swarm
./scripts/deploy-swarm.sh

# Check deployment
docker stack ps godot-pipeline

# Remove from Swarm
./scripts/remove-swarm.sh
```

## Service-Specific Notes

### Consumer Processor Optimizer (Main Production Service)
- Runs 6 replicas in production
- Handles Godot asset optimization and processing
- Key environment: `PROCESS_METHOD=godot_optimizer`
- Default env file: `services/consumer-processor/.env.godot-optimizer`

### Entity Queue Producer
- Manages entity queues and produces messages
- Integrates with Decentraland's catalyst storage
- Supports processing by entity ID, coordinates, or world names
- Default env file: `services/entity-queue-producer/.env`

### CRDT Runner
- Processes scene operations for Decentraland
- Located in: `services/consumer-processor/dependencies/crdt-runner/`
- Has its own build and test scripts

## AWS Integration Points
- S3: Asset storage (configured via BUCKET environment variable)
- SQS: Task queues (regular and priority queues)
- SNS: Notifications (configured via SNS_TOPIC_ARN)

## Architecture Awareness
The build system automatically detects CPU architecture:
- ARM64 (Apple Silicon) downloads ARM64 Godot executable
- x86_64 systems download x86_64 Godot executable

## Common Development Patterns

### Adding New Features
1. Identify which service needs modification
2. Use `./dev.sh <service> --shell` to explore the container
3. Make changes and test locally with `./dev.sh <service> --build`
4. Run tests: `yarn workspace <service-name> test`
5. Check linting: `yarn lint:check`

### Debugging Issues
1. Check logs: `./dev-helper.sh logs <service>`
2. Open shell in container: `./dev.sh <service> --shell`
3. Inside container: inspect files, check environment, run Node debugger

### Environment Configuration
Each service has default .env files. To customize:
1. Copy the default: `cp services/<service>/.env.default services/<service>/.env.local`
2. Edit the custom file
3. Run with: `./dev.sh <service> --env .env.local`

## Key File Locations
- Service implementations: `services/*/src/`
- Dockerfiles: `services/*/Dockerfile`
- Environment configs: `services/*/.env*`
- Deployment configs: `docker-compose.yml`, `docker-stack.yml`
- Helper scripts: `dev.sh`, `dev-helper.sh`, `scripts/`