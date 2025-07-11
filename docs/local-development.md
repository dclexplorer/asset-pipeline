# Local Development Guide

This guide explains how to run individual services locally for development using the improved development scripts.

## Prerequisites

- Docker and Docker Compose
- Node.js 18+ 
- Git

## Quick Start

### 1. Initial Setup

```bash
# Set up development environment
./dev-helper.sh setup
```

This will:
- Install all dependencies
- Create necessary local directories
- Validate Docker installation

### 2. Run Individual Services

```bash
# Run the consumer-processor-optimizer (main service for production)
./dev.sh consumer-processor-optimizer --build

# Run entity-queue-producer
./dev.sh entity-queue-producer --build

# Run status-service
./dev.sh status-service --build
```

## Development Scripts

### Main Development Script: `./dev.sh`

The main script for running individual services with full configuration control.

#### Basic Usage

```bash
./dev.sh <service> [options]
```

#### Available Services

| Service | Description | Default Port |
|---------|-------------|--------------|
| `consumer-processor` | Main consumer processor service | 8080 |
| `consumer-processor-optimizer` | Godot asset optimizer (**production main**) | 8080 |
| `consumer-processor-crdt` | CRDT runner | 8080 |
| `consumer-processor-godot` | Godot runner | 8080 |
| `entity-queue-producer` | Entity queue producer | 8081 |
| `status-service` | Status monitoring service | 8082 |

#### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--build` | Build Docker image before running | `./dev.sh consumer-processor-optimizer --build` |
| `--port <port>` | Override default port | `./dev.sh entity-queue-producer --port 8090` |
| `--env <file>` | Use custom environment file | `./dev.sh status-service --env .env.production` |
| `--detach, -d` | Run in detached mode | `./dev.sh consumer-processor-optimizer --detach` |
| `--logs` | Show logs (use with --detach) | `./dev.sh consumer-processor-optimizer --detach --logs` |
| `--shell` | Open shell instead of running service | `./dev.sh consumer-processor-optimizer --shell` |

### Helper Script: `./dev-helper.sh`

Additional development utilities and common operations.

#### Commands

```bash
# Initial setup
./dev-helper.sh setup

# Build all images
./dev-helper.sh build-all

# Show running containers
./dev-helper.sh ps

# Show logs for a service
./dev-helper.sh logs consumer-processor-optimizer

# Stop a specific service
./dev-helper.sh stop consumer-processor-optimizer

# Stop all development containers
./dev-helper.sh stop-all

# Open shell in running container
./dev-helper.sh shell consumer-processor-optimizer

# Run tests for a service
./dev-helper.sh test entity-queue-producer

# Run linting for a service
./dev-helper.sh lint consumer-processor

# Clean up Docker resources
./dev-helper.sh clean
```

## Environment Configuration

Each service has its own environment file for local development:

### Consumer Processor Services

- **Main**: `services/consumer-processor/.env.default`
- **Optimizer**: `services/consumer-processor/.env.godot-optimizer`
- **CRDT**: `services/consumer-processor/.env.crdt-runner`
- **Godot**: `services/consumer-processor/.env.godot-runner`

### Other Services

- **Entity Queue Producer**: `services/entity-queue-producer/.env`
- **Status Service**: `services/status-service/.env`

### Customizing Environment

1. **Copy default environment file**:
   ```bash
   cp services/consumer-processor/.env.godot-optimizer services/consumer-processor/.env.local
   ```

2. **Edit with your settings**:
   ```bash
   nano services/consumer-processor/.env.local
   ```

3. **Use custom environment**:
   ```bash
   ./dev.sh consumer-processor-optimizer --env .env.local
   ```

## Common Development Workflows

### Running the Main Production Service Locally

The `consumer-processor-optimizer` is the main service deployed 6x in production:

```bash
# Build and run the optimizer
./dev.sh consumer-processor-optimizer --build

# Run in detached mode with logs
./dev.sh consumer-processor-optimizer --build --detach --logs

# Open shell to debug
./dev.sh consumer-processor-optimizer --shell
```

### Running Multiple Services

```bash
# Terminal 1: Run optimizer
./dev.sh consumer-processor-optimizer --build --detach

# Terminal 2: Run entity queue producer
./dev.sh entity-queue-producer --build --detach

# Terminal 3: Run status service
./dev.sh status-service --build --detach

# View all running services
./dev-helper.sh ps
```

### Development Cycle

```bash
# 1. Make code changes
# 2. Rebuild and run
./dev.sh consumer-processor-optimizer --build

# 3. Test changes
./dev-helper.sh test consumer-processor

# 4. Lint code
./dev-helper.sh lint consumer-processor

# 5. View logs
./dev-helper.sh logs consumer-processor-optimizer
```

### Debugging

```bash
# Open shell in running container
./dev.sh consumer-processor-optimizer --shell

# Inside container:
# - Inspect files: ls -la /app
# - Check environment: env
# - Run commands manually: node dist/index.js
# - Debug with Node: node --inspect dist/index.js
```

## Service-Specific Notes

### Consumer Processor Optimizer

This is the **main production service** that runs 6 replicas. It handles:
- Godot asset optimization
- Asset processing workflows
- S3 integration for asset storage

**Key environment variables**:
```bash
PROCESS_METHOD=godot_optimizer
AWS_REGION=us-east-1
BUCKET=your-assets-bucket
```

### Entity Queue Producer

Manages entity queues and produces messages for processing.

**Key environment variables**:
```bash
SNS_TOPIC_ARN=arn:aws:sns:...
CATALYST_STORAGE_URL=https://catalyst-storage.decentraland.org
```

### Status Service

Monitors health of all services (currently placeholder implementation).

**Key environment variables**:
```bash
SERVICES_CONFIG='{"consumer-processor": {"url": "http://localhost:8080"}}'
```

## Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   ./dev.sh consumer-processor-optimizer --port 8090
   ```

2. **Environment variables not set**:
   - Check `.env` files in service directories
   - Copy from `.env.default` and customize

3. **Docker build fails**:
   ```bash
   # Clean up and rebuild
   ./dev-helper.sh clean
   ./dev.sh consumer-processor-optimizer --build
   ```

4. **Service won't start**:
   ```bash
   # Check logs
   ./dev-helper.sh logs consumer-processor-optimizer
   
   # Open shell to debug
   ./dev.sh consumer-processor-optimizer --shell
   ```

5. **Architecture Issues (ARM64 vs x86_64)**:
   - The build system automatically detects your architecture
   - ARM64 Macs will download the ARM64 Godot executable
   - x86_64 systems will download the x86_64 Godot executable
   - If you encounter architecture mismatches, rebuild with: `./dev.sh consumer-processor-optimizer --build`

### Getting Help

```bash
# Show help for main script
./dev.sh --help

# Show help for helper script
./dev-helper.sh
```

## Performance Tips

1. **Use detached mode** for long-running development sessions
2. **Build images once** and reuse them during development
3. **Use volumes** for faster code changes (already configured)
4. **Clean up regularly** to free disk space

```bash
# Regular cleanup
./dev-helper.sh clean
```

## Integration with IDE

### VS Code

Add to `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run Consumer Optimizer",
            "type": "shell",
            "command": "./dev.sh consumer-processor-optimizer --build",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        }
    ]
}
```

### Docker Extension

Use the Docker extension to:
- View running containers
- Access container logs
- Execute commands in containers

## Next Steps

- Set up your environment variables in `.env` files
- Run the main service: `./dev.sh consumer-processor-optimizer --build`
- Test different configurations and modes
- Develop and test your changes locally before deployment