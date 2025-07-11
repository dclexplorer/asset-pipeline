# Godot Server Pipeline

A monorepo containing microservices for processing Godot-based content in Decentraland's infrastructure.

## Architecture

This monorepo contains the following services:

### Services

1. **consumer-processor** - Main processing service with multiple execution modes:
   - **Main Service**: HTTP server for processing requests
   - **CRDT Runner**: Processes Conflict-free Replicated Data Type operations
   - **Godot Optimizer**: Optimizes Godot assets using the Godot editor
   - **Godot Runner**: Executes Godot explorer for various tasks

2. **entity-queue-producer** - Manages entity queues and produces messages for processing

3. **status-service** - *(Future)* Service health monitoring and status reporting

## Quick Start

### Prerequisites

- Node.js >= 18.0.0
- Docker & Docker Compose
- Docker Swarm (for production deployment)

### Local Development

1. **Quick setup**:
   ```bash
   ./dev-helper.sh setup
   ```

2. **Run individual services**:
   ```bash
   # Run the main production service (consumer-processor-optimizer)
   ./dev.sh consumer-processor-optimizer --build
   
   # Run entity queue producer
   ./dev.sh entity-queue-producer --build
   
   # Run status service
   ./dev.sh status-service --build
   ```

3. **Development tools**:
   ```bash
   # View running services
   ./dev-helper.sh ps
   
   # Show logs
   ./dev-helper.sh logs consumer-processor-optimizer
   
   # Stop all services
   ./dev-helper.sh stop-all
   ```

   See [Local Development Guide](docs/local-development.md) for detailed instructions.

4. **Run with Docker Compose** (all services):
   ```bash
   docker-compose up
   ```

### Production Deployment (Docker Swarm)

1. **Build and deploy to Swarm**:
   ```bash
   ./scripts/deploy-swarm.sh
   ```

2. **Check deployment status**:
   ```bash
   docker stack ps godot-pipeline
   ```

3. **Remove from Swarm**:
   ```bash
   ./scripts/remove-swarm.sh
   ```

## Services Overview

### Consumer Processor

The consumer-processor service runs in multiple modes:

- **Port 8080**: Main HTTP service
- **CRDT Runner**: Background CRDT processing
- **Godot Optimizer**: Asset optimization with Godot editor
- **Godot Runner**: Godot explorer execution

### Entity Queue Producer

- **Port 8081**: HTTP service for queue management
- Produces messages for the consumer-processor services

### Status Service (Future)

- **Port 8082**: Health monitoring and status reporting
- Will provide centralized monitoring for all services

## Docker Images

The following Docker images are built:

- `godot-pipeline/consumer-processor:latest`
- `godot-pipeline/consumer-processor-crdt:latest`
- `godot-pipeline/consumer-processor-optimizer:latest`
- `godot-pipeline/consumer-processor-godot:latest`
- `godot-pipeline/entity-queue-producer:latest`

## Scripts

- `./scripts/build-images.sh` - Build all Docker images
- `./scripts/deploy-swarm.sh` - Deploy to Docker Swarm
- `./scripts/remove-swarm.sh` - Remove from Docker Swarm

## Development

### Monorepo Structure

```
godot-server-pipeline/
├── services/
│   ├── consumer-processor/
│   │   ├── dependencies/
│   │   │   ├── crdt-runner/
│   │   │   ├── godot-asset-optimizer-project/
│   │   │   └── godot-runner/
│   │   └── src/
│   └── entity-queue-producer/
│       └── src/
├── scripts/
├── docs/
├── docker-compose.yml
├── docker-stack.yml
└── package.json
```

### Adding New Services

1. Create service directory under `services/`
2. Add service to `docker-compose.yml` and `docker-stack.yml`
3. Update build scripts
4. Add to monorepo `package.json` workspaces

### Running Individual Services

```bash
# Consumer processor
yarn workspace consumer-processor start

# Entity queue producer
yarn workspace entity-queue-producer start
```

## Environment Variables

Each service supports environment variables for configuration. Check individual service documentation for details.

## Monitoring

Service health endpoints:
- Consumer Processor: `http://localhost:8080/health`
- Entity Queue Producer: `http://localhost:8081/health`
- Status Service: `http://localhost:8082/health` *(Future)*

## Contributing

1. Make changes to services in `services/` directory
2. Update Docker configurations if needed
3. Test locally with `docker-compose up`
4. Deploy to Swarm for integration testing

## License

See individual service licenses.