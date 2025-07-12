# GitHub Actions Deployment Setup

This guide explains how to set up automatic deployment to Docker Swarm using GitHub Actions.

## Prerequisites

1. **Docker Swarm cluster** - Your target deployment environment
2. **SSH access** to the Docker Swarm manager node
3. **GitHub repository** with the codebase

## GitHub Repository Secrets

Set the following secrets in your GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

### Required Secrets

#### AWS Services (SQS/SNS)
| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_REGION` | AWS region for SQS/SNS services | `us-east-1` |
| `AWS_ACCESS_KEY_ID` | AWS access key ID for SQS/SNS | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key for SQS/SNS | `wJalrXUtnFEMI/K7MDENG/...` |

#### SQS Queues
| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SQS_QUEUE_URL` | Main SQS queue URL for processing | `https://sqs.us-east-1.amazonaws.com/123456789012/my-queue` |
| `PRIORITY_SQS_QUEUE_URL` | Priority SQS queue URL | `https://sqs.us-east-1.amazonaws.com/123456789012/priority-queue` |

#### SNS Topics
| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SNS_TOPIC_ARN` | SNS topic ARN for consumer notifications | `arn:aws:sns:us-east-1:123456789012:my-topic` |
| `SCENE_SNS_ARN` | SNS topic ARN for scene deployments | `arn:aws:sns:us-east-1:123456789012:scene-topic` |
| `PRIORITY_SCENE_SNS_ARN` | SNS topic ARN for priority scenes | `arn:aws:sns:us-east-1:123456789012:priority-scene-topic` |
| `WEARABLE_EMOTES_SNS` | SNS topic ARN for wearables/emotes | `arn:aws:sns:us-east-1:123456789012:wearable-emotes-topic` |

#### CloudFlare R2 Storage (S3-compatible)
| Secret Name | Description | Example |
|-------------|-------------|---------| 
| `S3_BUCKET` | S3/R2 bucket for asset storage | `my-godot-assets-bucket` |
| `S3_ACCESS_KEY_ID` | S3/R2 storage access key ID | `your-r2-access-key` |
| `S3_SECRET_ACCESS_KEY` | S3/R2 storage secret access key | `your-r2-secret-key` |
| `S3_ENDPOINT` | S3/R2 endpoint URL (for R2) | `https://accountid.r2.cloudflarestorage.com` |

#### Decentraland Services
| Secret Name | Description | Example |
|-------------|-------------|---------|
| `CATALYST_STORAGE_URL` | Catalyst storage service URL | `https://catalyst-storage.decentraland.org` |
| `SNAPSHOTS_FETCHER_URL` | Snapshots fetcher service URL | `https://snapshots-fetcher.decentraland.org` |

### Deployment Server Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SWARM_HOST` | Docker Swarm manager node IP/hostname | `192.168.1.100` or `swarm.mydomain.com` |
| `SWARM_USERNAME` | SSH username for the swarm node | `ubuntu` or `deploy` |
| `SWARM_SSH_KEY` | Private SSH key for authentication | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `SWARM_PORT` | SSH port (optional, defaults to 22) | `22` |

### Optional Secrets

| Secret Name | Description | Default |
|-------------|-------------|---------|
| `NODE_ENV` | Node.js environment | `production` |
| `ENTITY_QUEUE_PORT` | Entity queue producer port | `8081` |
| `STATUS_SERVICE_PORT` | Status service port | `8082` |

## Setting Up SSH Access

### 1. Generate SSH Key Pair

On your local machine:

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy
```

### 2. Copy Public Key to Server

```bash
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub username@your-server-ip
```

Or manually add the public key to `~/.ssh/authorized_keys` on your server.

### 3. Add Private Key to GitHub Secrets

Copy the private key content:

```bash
cat ~/.ssh/github_actions_deploy
```

Add this as the `SWARM_SSH_KEY` secret in GitHub.

## Docker Swarm Server Setup

### 1. Initialize Docker Swarm

On your deployment server:

```bash
# Initialize swarm (if not already done)
docker swarm init

# Or join existing swarm
docker swarm join --token <token> <manager-ip>:2377
```

### 2. Enable GitHub Container Registry

The deployment will pull images from GitHub Container Registry (ghcr.io). Ensure your server can access it:

```bash
# Test access
docker pull ghcr.io/hello-world
```

## Workflow Triggers

The GitHub Actions workflow triggers on:

1. **Push to main/master branch** - Automatic deployment
2. **Manual trigger** - Via GitHub Actions UI with environment selection

### Manual Deployment

1. Go to your repository on GitHub
2. Click `Actions` tab
3. Select `Deploy to Docker Swarm` workflow
4. Click `Run workflow`
5. Select environment (production/staging)
6. Click `Run workflow`

## Deployment Process

The workflow performs these steps:

1. **Checkout code** from the repository
2. **Build Docker images** for all services
3. **Push images** to GitHub Container Registry (ghcr.io)
4. **Connect to Docker Swarm** via SSH
5. **Deploy stack** with the new images
6. **Verify deployment** status

## Monitoring Deployment

### Via GitHub Actions

1. Go to `Actions` tab in your repository
2. Click on the running/completed workflow
3. View logs for each step

### On the Server

```bash
# Check stack status
docker stack ps godot-pipeline

# View service logs
docker service logs godot-pipeline_consumer-processor-optimizer
docker service logs godot-pipeline_entity-queue-producer
docker service logs godot-pipeline_status-service

# Check service details
docker service ls
docker service inspect godot-pipeline_consumer-processor-optimizer
```

## Rollback

If deployment fails or issues arise:

```bash
# Remove current stack
docker stack rm godot-pipeline

# Deploy previous version (manually specify image tag)
# Edit docker-stack.yml to use previous image tags
docker stack deploy -c docker-stack.yml godot-pipeline
```

## Security Best Practices

1. **Use least-privilege AWS IAM policies**
2. **Rotate SSH keys regularly**
3. **Use dedicated deployment user** on the server
4. **Enable two-factor authentication** on GitHub
5. **Review deployment logs** regularly
6. **Use branch protection rules** to prevent unauthorized deployments

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify `SWARM_HOST`, `SWARM_USERNAME`, and `SWARM_SSH_KEY`
   - Check if SSH key has correct permissions
   - Ensure server allows SSH connections

2. **Docker Image Pull Failed**
   - Verify GitHub Container Registry access
   - Check image names and tags
   - Ensure GitHub token has correct permissions

3. **Service Won't Start**
   - Check environment variables are set correctly
   - Verify AWS credentials and permissions
   - Check service logs: `docker service logs <service-name>`

4. **Stack Deployment Timeout**
   - Increase resources on Docker Swarm nodes
   - Check network connectivity between nodes
   - Verify volume mounts are accessible

### Getting Help

1. Check workflow logs in GitHub Actions
2. SSH to the server and check Docker logs
3. Verify all required secrets are set
4. Test manual deployment on the server first

## Example Complete Setup

```bash
# 1. Set up server
ssh user@your-server
docker swarm init

# 2. Set GitHub secrets (via GitHub UI)
# Add all required secrets listed above

# 3. Push to main branch or trigger manually
git push origin main

# 4. Monitor deployment
# Check GitHub Actions for progress
# SSH to server to verify services
```

The deployment will create:
- **6 replicas** of consumer-processor-optimizer
- **1 replica** of entity-queue-producer  
- **1 replica** of status-service

All services will be accessible via the configured ports and ready to process requests.