# Docker Swarm Setup and Deployment Guide

This guide provides comprehensive instructions for setting up Docker Swarm and deploying the Decentraland Asset Pipeline.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Docker Swarm Setup](#docker-swarm-setup)
- [Environment Configuration](#environment-configuration)
- [Manual Deployment](#manual-deployment)
- [Automated Deployment (GitHub Actions)](#automated-deployment-github-actions)
- [Monitoring and Management](#monitoring-and-management)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## Prerequisites

### System Requirements

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher (for local development)
- **Operating System**: Linux (Ubuntu 20.04+ recommended) or macOS
- **Resources**:
  - Minimum 16 CPUs (for production deployment)
  - Minimum 16GB RAM
  - 50GB+ available disk space

### AWS Resources

Before deployment, ensure you have:

1. **AWS Account** with appropriate permissions
2. **S3 Bucket** for asset storage
3. **SQS Queue** for task processing
4. **SNS Topic** for notifications
5. **IAM User** with access to above resources

### External Services

- Access to Decentraland's Catalyst Storage API
- Access to Snapshots Fetcher service

## Docker Swarm Setup

### 1. Initialize Docker Swarm

On your deployment server:

```bash
# Check if Swarm is already initialized
docker info | grep "Swarm: active"

# If not active, initialize Swarm
docker swarm init

# For multi-node setup with specific advertise address
docker swarm init --advertise-addr <MANAGER-IP>
```

### 2. Join Worker Nodes (Optional for Multi-Node Setup)

On the manager node, get the join token:

```bash
docker swarm join-token worker
```

On each worker node:

```bash
docker swarm join --token <TOKEN> <MANAGER-IP>:2377
```

### 3. Verify Swarm Setup

```bash
# List all nodes
docker node ls

# Verify Swarm is active
docker info | grep "Swarm: active"
```

## Environment Configuration

### Required Environment Variables

Create a `.env` file with all required variables:

```bash
# AWS Configuration
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-access-key

# AWS Services
export S3_BUCKET=your-asset-bucket
export SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/account-id/queue-name
export SNS_TOPIC_ARN=arn:aws:sns:us-east-1:account-id:topic-name

# External Services
export CATALYST_STORAGE_URL=https://peer.decentraland.org/content
export SNAPSHOTS_FETCHER_URL=https://snapshots-fetcher.decentraland.org

# Optional (with defaults)
export NODE_ENV=production
export ENTITY_QUEUE_PORT=8081
export STATUS_SERVICE_PORT=8082
export COMMIT_HASH=$(git rev-parse HEAD)
export CURRENT_VERSION=1.0.0
```

### Loading Environment Variables

```bash
# Option 1: Source the .env file
source .env

# Option 2: Export individually
export AWS_REGION=us-east-1
# ... etc

# Verify all required variables are set
./scripts/validate-env.sh
```

## Manual Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/decentraland/asset-pipeline.git
cd asset-pipeline
```

### 2. Set Up Environment Variables

```bash
# Copy and edit the environment file
cp .env.example .env
nano .env  # Edit with your values

# Load the variables
source .env
```

### 3. Deploy to Docker Swarm

```bash
# Run the deployment script
./scripts/deploy-swarm.sh
```

This script will:
1. Validate all required environment variables
2. Initialize Docker Swarm if needed
3. Build all Docker images
4. Deploy the stack to Swarm
5. Show deployment status

### 4. Verify Deployment

```bash
# Check stack status
docker stack ps godot-pipeline

# Check service status
docker service ls

# View logs for a specific service
docker service logs godot-pipeline_consumer-processor-optimizer
docker service logs godot-pipeline_entity-queue-producer
docker service logs godot-pipeline_status-service
```

## Automated Deployment (GitHub Actions)

### 1. Fork/Clone the Repository

Fork the repository to your GitHub account or organization.

### 2. Configure GitHub Secrets

Go to Settings → Secrets and variables → Actions, and add:

#### Deployment Secrets:
- `SWARM_HOST`: Your Docker Swarm manager IP/hostname
- `SWARM_USERNAME`: SSH username for deployment
- `SWARM_SSH_KEY`: Private SSH key for authentication
- `SWARM_PORT`: SSH port (optional, defaults to 22)

#### AWS Secrets:
- `AWS_REGION`: AWS region (e.g., us-east-1)
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `S3_BUCKET`: S3 bucket name
- `SQS_QUEUE_URL`: Full SQS queue URL
- `SNS_TOPIC_ARN`: SNS topic ARN

#### Service Configuration:
- `CATALYST_STORAGE_URL`: Catalyst storage API URL
- `SNAPSHOTS_FETCHER_URL`: Snapshots fetcher service URL
- `NODE_ENV`: Environment (optional, defaults to production)
- `ENTITY_QUEUE_PORT`: Entity queue port (optional, defaults to 8081)
- `STATUS_SERVICE_PORT`: Status service port (optional, defaults to 8082)

### 3. Deployment Triggers

The deployment workflow triggers on:
- Push to `main` or `master` branches
- Manual workflow dispatch

### 4. Manual Deployment via GitHub Actions

1. Go to Actions → Deploy to Docker Swarm
2. Click "Run workflow"
3. Select branch and click "Run workflow"

## Monitoring and Management

### Service Health Monitoring

```bash
# Check overall stack health
docker stack services godot-pipeline

# Monitor specific service
docker service ps godot-pipeline_consumer-processor-optimizer

# Real-time logs
docker service logs -f godot-pipeline_status-service
```

### Using the Status Service

The status service provides health endpoints:

```bash
# Check status service health
curl http://<SWARM-HOST>:8082/health

# Get detailed status
curl http://<SWARM-HOST>:8082/status
```

### Scaling Services

```bash
# Scale consumer-processor-optimizer (default is 6 replicas)
docker service scale godot-pipeline_consumer-processor-optimizer=10

# Scale back down
docker service scale godot-pipeline_consumer-processor-optimizer=6
```

### Rolling Updates

```bash
# Update a service with new image
docker service update --image godot-pipeline/consumer-processor-optimizer:new-tag \
  godot-pipeline_consumer-processor-optimizer

# Force update to redeploy with same image
docker service update --force godot-pipeline_consumer-processor-optimizer
```

## Troubleshooting

### Common Issues

#### 1. Environment Variable Missing

```bash
# Check which variables are missing
./scripts/validate-env.sh

# Export missing variables
export MISSING_VAR=value
```

#### 2. Service Fails to Start

```bash
# Check service logs
docker service logs godot-pipeline_<service-name>

# Check service tasks
docker service ps godot-pipeline_<service-name> --no-trunc

# Inspect service configuration
docker service inspect godot-pipeline_<service-name>
```

#### 3. AWS Connection Issues

```bash
# Test AWS credentials
aws s3 ls s3://$S3_BUCKET --region $AWS_REGION

# Check SQS access
aws sqs get-queue-attributes --queue-url $SQS_QUEUE_URL --region $AWS_REGION
```

#### 4. Resource Constraints

```bash
# Check node resources
docker node inspect self --pretty

# Update service resources if needed
docker service update \
  --limit-cpu 4 \
  --limit-memory 4G \
  godot-pipeline_consumer-processor-optimizer
```

### Rollback Deployment

```bash
# Rollback to previous version
docker service rollback godot-pipeline_consumer-processor-optimizer

# Remove and redeploy entire stack
./scripts/remove-swarm.sh
./scripts/deploy-swarm.sh
```

### Debug Mode

For debugging, you can run services individually:

```bash
# Run service with shell access
./dev.sh consumer-processor-optimizer --shell

# Check environment inside container
printenv | grep -E "AWS|S3|SQS|SNS"
```

## Security Considerations

### Best Practices

1. **Never commit secrets** to the repository
2. **Use read-only AWS credentials** when possible
3. **Rotate credentials regularly**
4. **Use Docker secrets** for sensitive data in production
5. **Enable TLS** for Swarm communication in multi-node setups

### Using Docker Secrets (Recommended for Production)

Instead of environment variables, use Docker secrets:

```bash
# Create secrets
echo "your-access-key" | docker secret create aws_access_key_id -
echo "your-secret-key" | docker secret create aws_secret_access_key -

# Update docker-stack.yml to use secrets
# See Docker documentation for secret usage in stack files
```

### Network Security

```bash
# Create encrypted overlay network
docker network create \
  --driver overlay \
  --opt encrypted \
  godot-pipeline-secure

# Update stack to use secure network
```

## Maintenance

### Regular Tasks

1. **Monitor disk usage** - Asset processing can consume significant space
2. **Check service logs** - Rotate logs to prevent disk fill
3. **Update images** - Pull latest images regularly
4. **Review metrics** - Monitor AWS costs and usage

### Backup Considerations

- Ensure S3 bucket has versioning enabled
- Backup environment configuration
- Document any custom modifications

### Updates and Upgrades

```bash
# Update to latest version
git pull origin main

# Rebuild and redeploy
./scripts/deploy-swarm.sh

# Or use GitHub Actions for automated deployment
```

---

For additional help or issues, please refer to:
- [Project README](README.md)
- [GitHub Issues](https://github.com/decentraland/asset-pipeline/issues)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)