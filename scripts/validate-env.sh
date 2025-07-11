#!/bin/bash

# Validate required environment variables for deployment
set -e

echo "Validating environment variables..."

# Required variables
REQUIRED_VARS=(
  "AWS_REGION"
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "S3_BUCKET"
  "SQS_QUEUE_URL"
  "SNS_TOPIC_ARN"
  "CATALYST_STORAGE_URL"
  "SNAPSHOTS_FETCHER_URL"
)

# Optional variables with defaults
OPTIONAL_VARS=(
  "NODE_ENV:production"
  "ENTITY_QUEUE_PORT:8081"
  "STATUS_SERVICE_PORT:8082"
  "COMMIT_HASH:local"
  "CURRENT_VERSION:Unknown"
)

MISSING_VARS=()
WARNING_VARS=()

# Check required variables
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var}" ]]; then
    MISSING_VARS+=("$var")
  else
    echo "✓ $var is set"
  fi
done

# Check optional variables
for var_def in "${OPTIONAL_VARS[@]}"; do
  var_name="${var_def%%:*}"
  var_default="${var_def#*:}"
  
  if [[ -z "${!var_name}" ]]; then
    WARNING_VARS+=("$var_name (will use default: $var_default)")
  else
    echo "✓ $var_name is set"
  fi
done

echo ""

# Report warnings
if [[ ${#WARNING_VARS[@]} -gt 0 ]]; then
  echo "⚠️  Optional variables using defaults:"
  for var in "${WARNING_VARS[@]}"; do
    echo "  - $var"
  done
  echo ""
fi

# Report missing variables
if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
  echo "❌ Missing required environment variables:"
  for var in "${MISSING_VARS[@]}"; do
    echo "  - $var"
  done
  echo ""
  echo "Please set these variables before deployment."
  echo "See docs/environment-variables.md for details."
  exit 1
fi

echo "✅ All required environment variables are set!"
echo ""
echo "Deployment configuration:"
echo "- consumer-processor-optimizer: 6 replicas"
echo "- entity-queue-producer: 1 replica"
echo "- status-service: 1 replica"
echo ""
echo "Ready to deploy!"