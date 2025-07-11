#!/usr/bin/env zsh

# Local Development Script for Godot Server Pipeline
# This script allows running individual services locally for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default values
BUILD_FLAG=false
SERVICE=""
MODE=""
PORT=""
ENV_FILE=""
EXTRA_ARGS=()
SERVICE_ARGS=()
DETACHED=false
LOGS=false
SHELL_MODE=false

# Available services
declare -A SERVICES=(
    ["consumer-processor"]="services/consumer-processor"
    ["consumer-processor-optimizer"]="services/consumer-processor"
    ["consumer-processor-crdt"]="services/consumer-processor"
    ["consumer-processor-godot"]="services/consumer-processor"
    ["entity-queue-producer"]="services/entity-queue-producer"
    ["status-service"]="services/status-service"
)

# Service configurations
declare -A SERVICE_CONFIGS=(
    ["consumer-processor"]="Dockerfile:8080:.env.default"
    ["consumer-processor-optimizer"]="dependencies/godot-asset-optimizer-project/Dockerfile:8080:.env.godot-optimizer"
    ["consumer-processor-crdt"]="dependencies/crdt-runner/Dockerfile:8080:.env.crdt-runner"
    ["consumer-processor-godot"]="dependencies/godot-runner/Dockerfile:8080:.env.godot-runner"
    ["entity-queue-producer"]="Dockerfile:8081:.env"
    ["status-service"]="Dockerfile:8082:.env"
)

# Usage message
usage() {
    echo -e "${BLUE}Godot Server Pipeline - Local Development Script${NC}"
    echo ""
    echo "Usage: ./dev.sh <service> [options]"
    echo ""
    echo -e "${YELLOW}Available Services:${NC}"
    echo "  consumer-processor           - Main consumer processor service"
    echo "  consumer-processor-optimizer - Godot asset optimizer (6 replicas in prod)"
    echo "  consumer-processor-crdt      - CRDT runner"
    echo "  consumer-processor-godot     - Godot runner"
    echo "  entity-queue-producer        - Entity queue producer"
    echo "  status-service               - Status monitoring service"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --build                      Build the Docker image before running"
    echo "  --port <port>                Override default port"
    echo "  --env <file>                 Use custom environment file"
    echo "  --detach, -d                 Run container in detached mode"
    echo "  --logs                       Show logs (use with --detach)"
    echo "  --shell                      Open shell in container instead of running service"
    echo "  --help, -h                   Show this help message"
    echo "  -- <args>                    Pass arguments to the service (after --)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./dev.sh consumer-processor-optimizer --build"
    echo "  ./dev.sh entity-queue-producer --port 8090"
    echo "  ./dev.sh status-service --detach"
    echo "  ./dev.sh consumer-processor-crdt --shell"
    echo ""
    echo -e "${YELLOW}Entity ID Processing Examples:${NC}"
    echo "  ./dev.sh consumer-processor-optimizer --build -- --entityId ba6fd4c87b4e0b28e0f3c4e8d1234567890abcdef"
    echo "  ./dev.sh consumer-processor-optimizer -- --entityId 100,100"
    echo "  ./dev.sh consumer-processor-optimizer -- --entityId myworld.dcl.eth"
    echo ""
    echo -e "${YELLOW}Environment Files:${NC}"
    echo "  Create .env files in service directories to configure environment variables"
    echo "  Use --env to specify custom environment file"
    echo ""
    exit 1
}

# Parse command line arguments
parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    # Check for help first
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        usage
    fi

    SERVICE="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case $1 in
            --build)
                BUILD_FLAG=true
                shift
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            --env)
                ENV_FILE="$2"
                shift 2
                ;;
            --detach|-d)
                DETACHED=true
                shift
                ;;
            --logs)
                LOGS=true
                shift
                ;;
            --shell)
                SHELL_MODE=true
                EXTRA_ARGS=("--entrypoint" "/bin/bash")
                shift
                ;;
            --help|-h)
                usage
                ;;
            --)
                # Everything after -- gets passed to the service
                shift
                SERVICE_ARGS+=("$@")
                break
                ;;
            *)
                echo -e "${RED}Error: Unknown option $1${NC}"
                usage
                ;;
        esac
    done
}

# Validate service
validate_service() {
    if [[ ! -v SERVICES["$SERVICE"] ]]; then
        echo -e "${RED}Error: Invalid service '$SERVICE'${NC}"
        echo ""
        echo "Available services:"
        for service in "${!SERVICES[@]}"; do
            echo "  - $service"
        done
        exit 1
    fi
}

# Get service configuration
get_service_config() {
    local config="${SERVICE_CONFIGS[$SERVICE]}"
    IFS=':' read -r DOCKERFILE DEFAULT_PORT DEFAULT_ENV <<< "$config"
    
    # Set defaults
    PORT="${PORT:-$DEFAULT_PORT}"
    ENV_FILE="${ENV_FILE:-$DEFAULT_ENV}"
}

# Build Docker image
build_image() {
    local service_dir="${SERVICES[$SERVICE]}"
    local image_name="dev-$SERVICE"
    
    echo -e "${BLUE}Building Docker image: $image_name${NC}"
    
    cd "$SCRIPT_DIR/$service_dir"
    
    # Detect host architecture for multi-platform builds
    local host_arch=$(uname -m)
    local docker_platform=""
    local use_buildx=false
    
    # Check if docker buildx is available
    if docker buildx version > /dev/null 2>&1; then
        use_buildx=true
        if [[ "$host_arch" == "arm64" || "$host_arch" == "aarch64" ]]; then
            docker_platform="--platform=linux/arm64"
            echo -e "${YELLOW}Detected ARM64 architecture, building for linux/arm64${NC}"
        else
            docker_platform="--platform=linux/amd64"
            echo -e "${YELLOW}Detected x86_64 architecture, building for linux/amd64${NC}"
        fi
    else
        echo -e "${YELLOW}Docker Buildx not available, using regular docker build${NC}"
        echo -e "${YELLOW}Note: This may cause architecture issues on ARM64 systems${NC}"
    fi
    
    if [[ "$use_buildx" == true ]]; then
        echo -e "${BLUE}Using Docker Buildx with platform: $docker_platform${NC}"
        if [[ "$DOCKERFILE" == "Dockerfile" ]]; then
            echo -e "${BLUE}Running: docker buildx build $docker_platform -t \"$image_name\" --load .${NC}"
            docker buildx build $docker_platform -t "$image_name" --load .
        else
            echo -e "${BLUE}Running: docker buildx build $docker_platform -f \"$DOCKERFILE\" -t \"$image_name\" --load .${NC}"
            docker buildx build $docker_platform -f "$DOCKERFILE" -t "$image_name" --load .
        fi
    else
        # Fallback to regular docker build
        if [[ "$DOCKERFILE" == "Dockerfile" ]]; then
            docker build -t "$image_name" .
        else
            docker build -f "$DOCKERFILE" -t "$image_name" .
        fi
    fi
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to build Docker image${NC}"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    echo -e "${GREEN}✓ Image built successfully${NC}"
}

# Prepare environment
prepare_env() {
    local service_dir="${SERVICES[$SERVICE]}"
    local env_path="$SCRIPT_DIR/$service_dir/$ENV_FILE"
    
    # Check if environment file exists
    if [[ -f "$env_path" ]]; then
        echo -e "${GREEN}✓ Using environment file: $env_path${NC}"
        ENV_ARGS=("--env-file" "$env_path")
    else
        echo -e "${YELLOW}⚠ Environment file not found: $env_path${NC}"
        ENV_ARGS=()
    fi
}

# Run container
run_container() {
    local image_name="dev-$SERVICE"
    local container_name="dev-$SERVICE-$(date +%s)"
    
    echo -e "${BLUE}Starting container: $container_name${NC}"
    echo -e "${BLUE}Service: $SERVICE${NC}"
    echo -e "${BLUE}Port: $PORT${NC}"
    
    # Prepare docker run arguments
    local docker_args=(
        "run"
        "--rm"
        "--name" "$container_name"
        "-p" "$PORT:$PORT"
        "-v" "$SCRIPT_DIR:/workspace"
    )
    
    # Add environment file if available
    if [[ ${#ENV_ARGS[@]} -gt 0 ]]; then
        docker_args+=("${ENV_ARGS[@]}")
    fi
    
    # Add detached mode if requested
    if [[ "$DETACHED" == true ]]; then
        docker_args+=("-d")
    else
        docker_args+=("-it")
    fi
    
    # Add extra arguments (like --entrypoint for shell)
    if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
        docker_args+=("${EXTRA_ARGS[@]}")
    fi
    
    # Add image name
    docker_args+=("$image_name")
    
    # Add service arguments if not in shell mode
    if [[ "$SHELL_MODE" == false && ${#SERVICE_ARGS[@]} -gt 0 ]]; then
        docker_args+=("${SERVICE_ARGS[@]}")
    fi
    
    # Run the container
    echo -e "${YELLOW}Running: docker ${docker_args[*]}${NC}"
    if [[ ${#SERVICE_ARGS[@]} -gt 0 && "$SHELL_MODE" == false ]]; then
        echo -e "${YELLOW}Service arguments: ${SERVICE_ARGS[*]}${NC}"
    fi
    echo ""
    
    docker "${docker_args[@]}"
    
    # Show logs if detached and logs requested
    if [[ "$DETACHED" == true && "$LOGS" == true ]]; then
        echo -e "${BLUE}Following logs for container: $container_name${NC}"
        docker logs -f "$container_name"
    fi
    
    if [[ "$DETACHED" == true ]]; then
        echo -e "${GREEN}✓ Container started in detached mode${NC}"
        echo "Container name: $container_name"
        echo "View logs: docker logs -f $container_name"
        echo "Stop container: docker stop $container_name"
    fi
}

# Show service info
show_service_info() {
    echo -e "${BLUE}=== Service Information ===${NC}"
    echo "Service: $SERVICE"
    echo "Directory: ${SERVICES[$SERVICE]}"
    echo "Dockerfile: $DOCKERFILE"
    echo "Port: $PORT"
    echo "Environment file: $ENV_FILE"
    echo ""
}

# Main execution
main() {
    parse_args "$@"
    validate_service
    get_service_config
    show_service_info
    
    if [[ "$BUILD_FLAG" == true ]]; then
        build_image
    fi
    
    prepare_env
    run_container
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Run main function
main "$@"