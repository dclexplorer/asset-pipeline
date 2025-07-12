# Environment Variables

This document lists all environment variables required for deploying the Godot Server Pipeline.

## Required Environment Variables

### AWS Configuration (SQS/SNS)
These variables are required for AWS SQS/SNS services:

| Variable | Description | Required For | Example |
|----------|-------------|--------------|---------| 
| `AWS_REGION` | AWS region for SQS/SNS services | All services | `us-east-1` |
| `AWS_ACCESS_KEY_ID` | AWS access key ID for SQS/SNS | All services | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key for SQS/SNS | All services | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

### S3-Compatible Storage (CloudFlare R2)
| Variable | Description | Required For | Example |
|----------|-------------|--------------|---------|
| `S3_BUCKET` | S3/R2 bucket name for asset storage | consumer-processor-optimizer | `my-godot-assets-bucket` |
| `S3_ACCESS_KEY_ID` | S3/R2 storage access key ID | consumer-processor-optimizer | `your-r2-access-key` |
| `S3_SECRET_ACCESS_KEY` | S3/R2 storage secret access key | consumer-processor-optimizer | `your-r2-secret-key` |
| `S3_ENDPOINT` | S3/R2 endpoint URL (for R2) | consumer-processor-optimizer | `https://accountid.r2.cloudflarestorage.com` |

### SQS Queues
| Variable | Description | Required For | Example |
|----------|-------------|--------------|---------|
| `SQS_QUEUE_URL` | Main SQS queue URL (mapped to TASK_QUEUE) | consumer-processor-optimizer | `https://sqs.us-east-1.amazonaws.com/123456789012/my-queue` |
| `PRIORITY_SQS_QUEUE_URL` | Priority SQS queue URL (mapped to PRIORITY_TASK_QUEUE) | consumer-processor-optimizer | `https://sqs.us-east-1.amazonaws.com/123456789012/priority-queue` |

### SNS Topics
| Variable | Description | Required For | Example |
|----------|-------------|--------------|---------|
| `SNS_TOPIC_ARN` | SNS topic ARN for consumer notifications (mapped to SNS_ARN) | consumer-processor-optimizer | `arn:aws:sns:us-east-1:123456789012:my-topic` |
| `SCENE_SNS_ARN` | SNS topic ARN for scene deployments | entity-queue-producer | `arn:aws:sns:us-east-1:123456789012:scene-topic` |
| `PRIORITY_SCENE_SNS_ARN` | SNS topic ARN for priority scenes | entity-queue-producer | `arn:aws:sns:us-east-1:123456789012:priority-scene-topic` |
| `WEARABLE_EMOTES_SNS` | SNS topic ARN for wearables/emotes | entity-queue-producer | `arn:aws:sns:us-east-1:123456789012:wearable-emotes-topic` |

### Service URLs
| Variable | Description | Required For | Example |
|----------|-------------|--------------|---------|
| `CATALYST_STORAGE_URL` | Catalyst storage service URL | entity-queue-producer | `https://catalyst-storage.decentraland.org` |
| `SNAPSHOTS_FETCHER_URL` | Snapshots fetcher service URL | entity-queue-producer | `https://snapshots-fetcher.decentraland.org` |

### Service Ports (Optional)
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `ENTITY_QUEUE_PORT` | Entity queue producer port | `8081` | `8081` |
| `STATUS_SERVICE_PORT` | Status service port | `8082` | `8082` |

### Application Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `NODE_ENV` | Node.js environment | `production` | `production` |
| `COMMIT_HASH` | Git commit hash for tracking | `local` | `abc123def` |
| `CURRENT_VERSION` | Application version | `Unknown` | `v1.0.0` |

## Environment Variables by Service

### consumer-processor-optimizer (6 replicas)
```bash
NODE_ENV=production
MODE=asset-optimizer
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
S3_BUCKET=your-r2-bucket
S3_ACCESS_KEY_ID=your-r2-access-key
S3_SECRET_ACCESS_KEY=your-r2-secret-key
S3_ENDPOINT=https://accountid.r2.cloudflarestorage.com
SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/your-queue
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456789012:your-topic
COMMIT_HASH=abc123def
CURRENT_VERSION=v1.0.0
```

### entity-queue-producer (1 replica)
```bash
NODE_ENV=production
PORT=8081
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456789012:your-topic
CATALYST_STORAGE_URL=https://catalyst-storage.decentraland.org
SNAPSHOTS_FETCHER_URL=https://snapshots-fetcher.decentraland.org
```

### status-service (1 replica)
```bash
NODE_ENV=production
PORT=8082
```

## Setting Environment Variables

### Docker Swarm Deployment
Create a `.env` file in the project root:

```bash
# .env
NODE_ENV=production
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
S3_BUCKET=your-r2-bucket
S3_ACCESS_KEY_ID=your-r2-access-key-id
S3_SECRET_ACCESS_KEY=your-r2-secret-access-key
S3_ENDPOINT=https://accountid.r2.cloudflarestorage.com
SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/your-queue
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456789012:your-topic
CATALYST_STORAGE_URL=https://catalyst-storage.decentraland.org
SNAPSHOTS_FETCHER_URL=https://snapshots-fetcher.decentraland.org
ENTITY_QUEUE_PORT=8081
STATUS_SERVICE_PORT=8082
COMMIT_HASH=abc123def
CURRENT_VERSION=v1.0.0
```

### GitHub Actions Secrets
For GitHub Actions deployment, set these as repository secrets:

**Required Secrets:**
- `AWS_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `S3_BUCKET`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- `S3_ENDPOINT`
- `SQS_QUEUE_URL`
- `SNS_TOPIC_ARN`
- `CATALYST_STORAGE_URL`
- `SNAPSHOTS_FETCHER_URL`
- `DOCKER_REGISTRY_URL` (if using private registry)
- `DOCKER_USERNAME` (if using private registry)
- `DOCKER_PASSWORD` (if using private registry)

**Optional Secrets:**
- `ENTITY_QUEUE_PORT`
- `STATUS_SERVICE_PORT`

## Security Notes

1. **Never commit sensitive environment variables** to version control
2. **Use GitHub Secrets** for CI/CD deployments
3. **Rotate AWS credentials regularly**
4. **Use IAM roles with minimal permissions** when possible
5. **Consider using AWS Parameter Store or Secrets Manager** for production deployments

## Validation

To validate your environment variables are set correctly:

```bash
# Check if all required variables are set
./scripts/validate-env.sh
```

This script will verify all required environment variables are present before deployment.