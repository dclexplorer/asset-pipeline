# Entity Processing with dev.sh

This guide explains how to use the dev.sh script to process specific entities locally for development and testing.

## Entity ID Processing

The consumer-processor services support scheduling specific entities for processing using the `--entityId` argument. You can pass this argument through the dev.sh script using the `--` separator.

## Supported Entity ID Formats

### 1. Direct Entity ID
Process a specific entity by its ID:
```bash
./dev.sh consumer-processor-optimizer --build -- --entityId ba6fd4c87b4e0b28e0f3c4e8d1234567890abcdef
```

### 2. Coordinates
Process entities at specific coordinates (resolves via Decentraland peer API):
```bash
./dev.sh consumer-processor-optimizer -- --entityId 100,100
./dev.sh consumer-processor-optimizer -- --entityId -50,25
```

### 3. World Names
Process entities from Decentraland worlds (.dcl.eth domains):
```bash
./dev.sh consumer-processor-optimizer -- --entityId myworld.dcl.eth
./dev.sh consumer-processor-optimizer -- --entityId genesis-plaza.dcl.eth
```

## Examples

### Quick Testing (using pre-built image)
```bash
# Process coordinates
./dev.sh consumer-processor-optimizer -- --entityId 0,0

# Process a world
./dev.sh consumer-processor-optimizer -- --entityId foundation.dcl.eth
```

### Development (with rebuild)
```bash
# Build and process entity
./dev.sh consumer-processor-optimizer --build -- --entityId ba6fd4c87b4e0b28e0f3c4e8d1234567890abcdef
```

### Background Processing
```bash
# Run in detached mode and follow logs
./dev.sh consumer-processor-optimizer --detach --logs -- --entityId 100,100
```

### Custom Environment
```bash
# Use custom environment file
./dev.sh consumer-processor-optimizer --env .env.production -- --entityId myworld.dcl.eth
```

## How Entity Processing Works

1. **Coordinates (x,y)**: Makes API call to `https://peer.decentraland.org/content/entities/active` to resolve coordinates to entity ID
2. **World names (.dcl.eth)**: Makes API call to worlds content server to get scene URN and extract entity ID
3. **Direct entity ID**: Uses the ID directly

The resolved entity ID is then published to the task queue for processing by the appropriate runner (Godot optimizer, CRDT processor, etc.).

## Monitoring Entity Processing

### View Logs
```bash
# Start service and watch logs
./dev.sh consumer-processor-optimizer --detach --logs -- --entityId 100,100

# Or view logs of running container
./dev-helper.sh logs consumer-processor-optimizer
```

### Debug Mode
```bash
# Open shell in container for debugging
./dev.sh consumer-processor-optimizer --shell

# Inside container, run manually:
node --trace-warnings --abort-on-uncaught-exception --unhandled-rejections=strict dist/index.js --entityId 100,100
```

## Environment Variables for Entity Processing

Key environment variables that affect entity processing:

```bash
# Queue configuration
TASK_QUEUE=https://sqs.us-east-1.amazonaws.com/123456789012/my-queue
PRIORITY_TASK_QUEUE=https://sqs.us-east-1.amazonaws.com/123456789012/my-priority-queue

# Storage configuration
BUCKET=my-assets-bucket
S3_ENDPOINT=https://s3.amazonaws.com

# Processing method
PROCESS_METHOD=godot_optimizer

# AWS credentials
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
```

## Troubleshooting

### Entity Not Found
```
Error: No entity ID found for the given pointer
```
- Check if coordinates are valid (within Decentraland map bounds)
- Verify world name exists and is properly formatted

### API Connection Issues
```
Failed to fetch entity ID: 404 Not Found
```
- Check internet connection
- Verify Decentraland peer services are accessible
- Try different coordinates or entity IDs

### Queue Publishing Errors
```
Error publishing to task queue
```
- Check AWS credentials and permissions
- Verify SQS queue URL is correct
- Ensure queue exists and is accessible

## Service-Specific Usage

### Consumer Processor Optimizer (Main Production Service)
```bash
# This is what runs 6x in production
./dev.sh consumer-processor-optimizer --build -- --entityId 100,100
```

### CRDT Runner
```bash
./dev.sh consumer-processor-crdt -- --entityId myworld.dcl.eth
```

### Godot Runner
```bash
./dev.sh consumer-processor-godot -- --entityId genesis-plaza.dcl.eth
```

## Advanced Usage

### Multiple Arguments
You can pass multiple arguments to the service:
```bash
./dev.sh consumer-processor-optimizer -- --entityId 100,100 --verbose --debug
```

### Custom Processing Pipeline
```bash
# Set specific processing method via environment
echo "PROCESS_METHOD=custom_processor" >> services/consumer-processor/.env.local
./dev.sh consumer-processor-optimizer --env .env.local -- --entityId 100,100
```

This allows you to test entity processing locally before deploying to the production Docker Swarm cluster.