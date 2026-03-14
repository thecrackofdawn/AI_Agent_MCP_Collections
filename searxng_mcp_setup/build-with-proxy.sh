#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect proxy configuration
detect_proxy() {
    log_info "Detecting proxy configuration..."

    # Check for common proxy environment variables
    if [ -n "$HTTP_PROXY" ] || [ -n "$http_proxy" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$https_proxy" ]; then
        # Use the first available proxy
        PROXY_HTTP="${HTTP_PROXY:-$http_proxy}"
        PROXY_HTTPS="${HTTPS_PROXY:-$https_proxy:-$PROXY_HTTP}"

        log_info "Proxy detected:"
        log_info "  HTTP_PROXY=$PROXY_HTTP"
        log_info "  HTTPS_PROXY=$PROXY_HTTPS"

        # Convert localhost/127.0.0.1 to host-gateway for Docker build
        # Docker build doesn't support host.docker.internal during build, so we use host-gateway
        if echo "$PROXY_HTTP" | grep -qE 'https?://(localhost|127\.0\.0\.1):'; then
            log_warn "Proxy uses localhost address"
            log_warn "During docker build, this will be mapped to the Docker gateway"
            log_warn "If build fails, ensure your proxy accepts connections from Docker network"
        fi

        return 0
    else
        log_info "No proxy detected in environment"
        return 1
    fi
}

# Build Docker image with proxy support
build_image() {
    local build_args=""

    if detect_proxy; then
        # For Docker build, we need to use special handling
        # Build-time proxy needs to be accessible from within the build container
        # For localhost proxies, Docker's host-gateway can be used

        log_info "Configuring build arguments for proxy..."

        # Convert localhost to Docker host gateway for build
        BUILD_PROXY_HTTP=$(echo "$PROXY_HTTP" | sed 's|://localhost:|://172.17.0.1:|' | sed 's|://127.0.0.1:|://172.17.0.1:|')
        BUILD_PROXY_HTTPS=$(echo "$PROXY_HTTPS" | sed 's|://localhost:|://172.17.0.1:|' | sed 's|://127.0.0.1:|://172.17.0.1:|')

        log_info "Build proxy arguments:"
        log_info "  HTTP_PROXY=$BUILD_PROXY_HTTP"
        log_info "  HTTPS_PROXY=$BUILD_PROXY_HTTPS"

        build_args="--build-arg BUILD_PROXY_HTTP=$BUILD_PROXY_HTTP"
        build_args="$build_args --build-arg BUILD_PROXY_HTTPS=$BUILD_PROXY_HTTPS"
    fi

    log_info "Building Docker image..."
    log_info "Command: docker build $build_args -t searxng-mcp:latest ."

    # Build the image
    eval docker build $build_args -t searxng-mcp:latest .

    if [ $? -eq 0 ]; then
        log_info "Build completed successfully!"
        log_info "Image: searxng-mcp:latest"
    else
        log_error "Build failed!"
        exit 1
    fi
}

# Main execution
main() {
    echo "======================================"
    echo "SearXNG + MCP Docker Build with Proxy"
    echo "======================================"
    echo

    build_image

    echo
    log_info "To run the container:"
    log_info "  docker run -p 8080:8080 -p 3000:3000 searxng-mcp:latest"
    echo
    log_info "Or with docker-compose:"
    log_info "  docker-compose up -d"
}

main
