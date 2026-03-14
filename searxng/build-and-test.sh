#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Docker is running
check_docker() {
    log_step "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    log_info "Docker is installed and running"
}

# Build the Docker image
build_image() {
    log_step "Building Docker image..."
    docker build -t searxng-mcp:latest .
    log_info "Image built successfully"
}

# Create necessary directories
setup_directories() {
    log_step "Setting up directories..."
    mkdir -p searxng-config
    log_info "Directories created"
}

# Create a sample configuration if it doesn't exist
create_sample_config() {
    if [ ! -f searxng-config/settings.yml ]; then
        log_step "Creating sample configuration..."
        cp settings.yml.example searxng-config/settings.yml
        log_warn "Created searxng-config/settings.yml - please review and customize"
    else
        log_info "Configuration file already exists"
    fi
}

# Run the container
run_container() {
    log_step "Starting container..."
    docker run -d \
        --name searxng-mcp-test \
        -p 8080:8080 \
        -p 3000:3000 \
        -v "$(pwd)/searxng-config:/etc/searxng" \
        searxng-mcp:latest

    log_info "Container started with name: searxng-mcp-test"
}

# Wait for services to be ready
wait_for_services() {
    log_step "Waiting for services to be ready..."

    local max_wait=60
    local waited=0

    while [ $waited -lt $max_wait ]; do
        # Check SearXNG
        if curl -f -s http://localhost:8080 > /dev/null 2>&1; then
            log_info "SearXNG is ready!"
            break
        fi

        echo -n "."
        sleep 2
        waited=$((waited + 2))
    done
    echo
}

# Test SearXNG
test_searxng() {
    log_step "Testing SearXNG..."
    if curl -f -s http://localhost:8080 > /dev/null; then
        log_info "SearXNG is responding on port 8080"
        return 0
    else
        log_error "SearXNG is not responding"
        return 1
    fi
}

# Test MCP server (if HTTP enabled)
test_mcp() {
    log_step "Testing MCP server..."
    if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
        log_info "MCP server is responding on port 3000"
        return 0
    else
        log_warn "MCP server HTTP transport may not be enabled"
        return 0
    fi
}

# Show logs
show_logs() {
    log_step "Container logs (last 20 lines):"
    docker logs --tail 20 searxng-mcp-test
}

# Cleanup
cleanup() {
    log_step "Cleaning up..."
    docker stop searxng-mcp-test 2>/dev/null || true
    docker rm searxng-mcp-test 2>/dev/null || true
    log_info "Cleanup complete"
}

# Main execution
main() {
    echo "======================================"
    echo "SearXNG + MCP Build and Test Script"
    echo "======================================"
    echo

    check_docker
    setup_directories
    create_sample_config
    build_image
    run_container
    wait_for_services

    echo
    log_info "Running tests..."
    echo

    test_searxng
    test_mcp

    echo
    show_logs

    echo
    log_info "Test complete!"
    echo
    log_info "Container is running. Access SearXNG at: http://localhost:8080"
    log_info "To stop the container, run: docker stop searxng-mcp-test"
    log_info "To remove the container, run: docker rm searxng-mcp-test"

    # Ask if user wants to cleanup
    echo
    read -p "Stop and remove the test container? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function
main
