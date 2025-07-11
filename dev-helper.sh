#!/usr/bin/env zsh

# Development Helper Script
# Provides common development operations and shortcuts

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo -e "${BLUE}Development Helper Script${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  setup                        Initial setup for development"
    echo "  build-all                    Build all Docker images"
    echo "  clean                        Clean up Docker images and containers"
    echo "  logs <service>               Show logs for running service"
    echo "  stop <service>               Stop running service"
    echo "  stop-all                     Stop all running dev containers"
    echo "  ps                           Show running dev containers"
    echo "  shell <service>              Open shell in service container"
    echo "  test <service>               Run tests for specific service"
    echo "  lint <service>               Run linting for specific service"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 setup"
    echo "  $0 build-all"
    echo "  $0 logs consumer-processor-optimizer"
    echo "  $0 shell entity-queue-producer"
    echo "  $0 stop-all"
    echo ""
    exit 1
}

setup() {
    echo -e "${BLUE}Setting up development environment...${NC}"
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Error: Docker is not running${NC}"
        exit 1
    fi
    
    # Install dependencies for all services
    echo -e "${YELLOW}Installing dependencies...${NC}"
    if command -v yarn > /dev/null; then
        yarn install
    else
        echo -e "${YELLOW}Yarn not found, using npm...${NC}"
        npm install
    fi
    
    # Create local directories for volumes
    echo -e "${YELLOW}Creating local directories...${NC}"
    mkdir -p tmp/godot-assets
    mkdir -p tmp/godot-projects
    mkdir -p tmp/logs
    
    echo -e "${GREEN}✓ Development environment setup complete${NC}"
    echo ""
    echo "You can now run services using:"
    echo "  ./dev.sh <service-name> --build"
}

build_all() {
    echo -e "${BLUE}Building all Docker images...${NC}"
    
    local services=("consumer-processor" "consumer-processor-optimizer" "consumer-processor-crdt" "consumer-processor-godot" "entity-queue-producer" "status-service")
    
    for service in "${services[@]}"; do
        echo -e "${YELLOW}Building $service...${NC}"
        ./dev.sh "$service" --build --detach > /dev/null 2>&1 || {
            echo -e "${RED}Failed to build $service${NC}"
            continue
        }
        echo -e "${GREEN}✓ $service built successfully${NC}"
        
        # Stop the container immediately since we just wanted to build
        docker stop "dev-$service-"* 2>/dev/null || true
    done
    
    echo -e "${GREEN}✓ All images built successfully${NC}"
}

clean() {
    echo -e "${BLUE}Cleaning up Docker resources...${NC}"
    
    # Stop all dev containers
    echo -e "${YELLOW}Stopping development containers...${NC}"
    docker ps -q --filter "name=dev-*" | xargs -r docker stop
    
    # Remove dev images
    echo -e "${YELLOW}Removing development images...${NC}"
    docker images -q --filter "reference=dev-*" | xargs -r docker rmi -f
    
    # Clean up unused Docker resources
    echo -e "${YELLOW}Cleaning up unused Docker resources...${NC}"
    docker system prune -f
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

show_logs() {
    local service="$1"
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    local container_name=$(docker ps --filter "name=dev-$service" --format "{{.Names}}" | head -1)
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: No running container found for service '$service'${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Showing logs for $container_name...${NC}"
    docker logs -f "$container_name"
}

stop_service() {
    local service="$1"
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Stopping $service containers...${NC}"
    docker ps -q --filter "name=dev-$service" | xargs -r docker stop
    echo -e "${GREEN}✓ Stopped $service containers${NC}"
}

stop_all() {
    echo -e "${YELLOW}Stopping all development containers...${NC}"
    docker ps -q --filter "name=dev-*" | xargs -r docker stop
    echo -e "${GREEN}✓ All development containers stopped${NC}"
}

show_ps() {
    echo -e "${BLUE}Development containers:${NC}"
    docker ps --filter "name=dev-*" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

open_shell() {
    local service="$1"
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Opening shell in $service...${NC}"
    ./dev.sh "$service" --shell
}

run_tests() {
    local service="$1"
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Running tests for $service...${NC}"
    
    case "$service" in
        "consumer-processor"|"consumer-processor-"*)
            cd "$SCRIPT_DIR/services/consumer-processor"
            ;;
        "entity-queue-producer")
            cd "$SCRIPT_DIR/services/entity-queue-producer"
            ;;
        "status-service")
            cd "$SCRIPT_DIR/services/status-service"
            ;;
        *)
            echo -e "${RED}Error: Unknown service '$service'${NC}"
            exit 1
            ;;
    esac
    
    if [[ -f "package.json" ]]; then
        npm test
    else
        echo -e "${YELLOW}No test script found for $service${NC}"
    fi
    
    cd "$SCRIPT_DIR"
}

run_lint() {
    local service="$1"
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Running lint for $service...${NC}"
    
    case "$service" in
        "consumer-processor"|"consumer-processor-"*)
            cd "$SCRIPT_DIR/services/consumer-processor"
            ;;
        "entity-queue-producer")
            cd "$SCRIPT_DIR/services/entity-queue-producer"
            ;;
        "status-service")
            cd "$SCRIPT_DIR/services/status-service"
            ;;
        *)
            echo -e "${RED}Error: Unknown service '$service'${NC}"
            exit 1
            ;;
    esac
    
    if [[ -f "package.json" ]] && npm run | grep -q "lint:check"; then
        npm run lint:check
    else
        echo -e "${YELLOW}No lint script found for $service${NC}"
    fi
    
    cd "$SCRIPT_DIR"
}

# Main execution
case "${1:-}" in
    setup)
        setup
        ;;
    build-all)
        build_all
        ;;
    clean)
        clean
        ;;
    logs)
        show_logs "$2"
        ;;
    stop)
        stop_service "$2"
        ;;
    stop-all)
        stop_all
        ;;
    ps)
        show_ps
        ;;
    shell)
        open_shell "$2"
        ;;
    test)
        run_tests "$2"
        ;;
    lint)
        run_lint "$2"
        ;;
    *)
        usage
        ;;
esac