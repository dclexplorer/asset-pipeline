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
- **visualizer**: Docker Swarm visualizer web UI (port 8088) - shows service distribution across nodes

### Technology Stack
- TypeScript/Node.js (v18+)
- Docker & Docker Compose for local development
- Docker Swarm for production deployment
- AWS services (S3 for asset storage, SQS for queues, SNS for notifications)
- CloudFlare R2 (S3-compatible storage) for asset storage
- Godot game engine for asset processing
- npm workspaces for monorepo management

## Essential Development Commands

### Build and Test
```bash
# Build all services
npm run build

# Run all tests
npm test

# Test specific service
npm run test --workspace=consumer-processor
npm run test --workspace=entity-queue-producer
npm run test --workspace=status-service

# Run single test file
npm run test --workspace=consumer-processor path/to/test.spec.ts

# Lint check/fix
npm run lint:check
npm run lint:fix
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

# Run with custom environment file
./dev.sh consumer-processor-optimizer --env .env.local
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

# Run specific service
docker-compose up consumer-processor-optimizer
```

### Production Deployment
```bash
# Deploy to Docker Swarm
./scripts/deploy-swarm.sh

# Check deployment
docker stack ps godot-pipeline

# View service logs
docker service logs godot-pipeline_consumer-processor-optimizer

# Access visualizer web UI
# http://<swarm-manager-ip>:8088

# Remove from Swarm
./scripts/remove-swarm.sh
```

## Service-Specific Notes

### Consumer Processor Optimizer (Main Production Service)
- Runs 6 replicas in production
- Handles Godot asset optimization and processing
- Key environment: `PROCESS_METHOD=godot_optimizer`
- Default env file: `services/consumer-processor/.env.godot-optimizer`
- Processes assets from SQS queue and stores results in S3/R2

### Entity Queue Producer
- Manages entity queues and produces messages
- Integrates with Decentraland's catalyst storage
- Supports processing by:
  - Entity ID: `/process-entity/{entityId}`
  - Coordinates: `/process-by-coords?x1=-50&y1=-50&x2=50&y2=50`
  - World names: `/process-world/{worldName}`
- Default env file: `services/entity-queue-producer/.env`
- Includes world-sync adapter for periodic world synchronization

### CRDT Runner
- Processes scene operations for Decentraland
- Located in: `services/consumer-processor/dependencies/crdt-runner/`
- Has its own build and test scripts
- Handles Conflict-free Replicated Data Type operations

### Status Service
- Health monitoring endpoint (port 8082)
- Currently a minimal implementation
- Future: Will provide centralized monitoring for all services

## AWS Integration Points
- **S3/CloudFlare R2**: Asset storage (configured via S3_BUCKET, S3_ENDPOINT)
- **SQS**: Task queues (regular via SQS_QUEUE_URL and priority via PRIORITY_SQS_QUEUE_URL)
- **SNS**: Notifications (configured via SNS_TOPIC_ARN, SCENE_SNS_ARN, etc.)

## Architecture Awareness
The build system automatically detects CPU architecture:
- ARM64 (Apple Silicon) downloads ARM64 Godot executable
- x86_64 systems download x86_64 Godot executable

## Common Development Patterns

### Adding New Features
1. Identify which service needs modification
2. Use `./dev.sh <service> --shell` to explore the container
3. Make changes and test locally with `./dev.sh <service> --build`
4. Run tests: `npm run test --workspace=<service-name>`
5. Check linting: `npm run lint:check`

### Debugging Issues
1. Check logs: `./dev-helper.sh logs <service>`
2. Open shell in container: `./dev.sh <service> --shell`
3. Inside container: inspect files, check environment, run Node debugger
4. Check health endpoints: `curl http://localhost:<port>/health`

### Environment Configuration
Each service has default .env files. To customize:
1. Copy the default: `cp services/<service>/.env.default services/<service>/.env.local`
2. Edit the custom file
3. Run with: `./dev.sh <service> --env .env.local`

Environment precedence: process env vars > .env > .env.default

## Key File Locations
- Service implementations: `services/*/src/`
- Dockerfiles: `services/*/Dockerfile`
- Environment configs: `services/*/.env*`
- Deployment configs: `docker-compose.yml`, `docker-stack.yml`
- Helper scripts: `dev.sh`, `dev-helper.sh`, `scripts/`
- Documentation: `docs/`, `SETUP.md`

## Service History
- consumer-processor: Migrated from deployments-sse repository
- entity-queue-producer: Migrated from deployments-to-sqs repository
- Both services were unified into this monorepo for better management