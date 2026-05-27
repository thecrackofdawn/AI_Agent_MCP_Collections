#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Function to setup proxy for container
# With host network mode, container shares host network stack, no address conversion needed
setup_container_proxy() {
    local has_proxy=0

    if [ -n "$HOST_HTTP_PROXY" ] || [ -n "$HOST_HTTPS_PROXY" ]; then
        log_info "Host proxy detected from environment variables" >&2
        has_proxy=1
    fi

    # Set HTTP proxy
    if [ -n "$HOST_HTTP_PROXY" ]; then
        echo "export HTTP_PROXY=\"$HOST_HTTP_PROXY\""
        echo "export http_proxy=\"$HOST_HTTP_PROXY\""
        log_info "HTTP_PROXY=$HOST_HTTP_PROXY" >&2
    fi

    # Set HTTPS proxy
    if [ -n "$HOST_HTTPS_PROXY" ]; then
        echo "export HTTPS_PROXY=\"$HOST_HTTPS_PROXY\""
        echo "export https_proxy=\"$HOST_HTTPS_PROXY\""
        echo "export HTTPX_PROXY=\"$HOST_HTTPS_PROXY\""
        echo "export httpx_proxy=\"$HOST_HTTPS_PROXY\""
        log_info "HTTPS_PROXY=$HOST_HTTPS_PROXY" >&2
    fi

    # Set ALL proxy
    if [ -n "$HOST_ALL_PROXY" ]; then
        echo "export ALL_PROXY=\"$HOST_ALL_PROXY\""
        echo "export all_proxy=\"$HOST_ALL_PROXY\""
        log_info "ALL_PROXY=$HOST_ALL_PROXY" >&2
    fi

    if [ $has_proxy -eq 1 ]; then
        log_info "Container proxy configured successfully" >&2
    else
        log_info "No host proxy configuration detected" >&2
    fi
}

# Function to check if SearXNG is ready
wait_for_searxng() {
    log_info "Waiting for SearXNG to be ready..."
    local max_attempts=60
    local attempt=1
    local health_url="http://localhost:3001/health"

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            log_info "SearXNG is ready!"
            return 0
        fi

        # Try alternate health check endpoints
        if curl -f -s "http://localhost:3001/" > /dev/null 2>&1; then
            log_info "SearXNG web interface is responding!"
            return 0
        fi

        log_warn "Attempt $attempt/$max_attempts: SearXNG not ready yet, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "SearXNG failed to start after $max_attempts attempts"
    return 1
}

# Function to handle graceful shutdown
shutdown_handler() {
    log_info "Shutdown signal received, stopping services..."

    # Kill background processes
    if [ -n "$MCP_PID" ]; then
        log_info "Stopping MCP server (PID: $MCP_PID)..."
        kill -TERM "$MCP_PID" 2>/dev/null || true
        wait "$MCP_PID" 2>/dev/null || true
    fi

    # The SearXNG process will also receive the signal
    log_info "Services stopped."
    exit 0
}

# Set signal traps
trap shutdown_handler SIGTERM SIGINT

# Setup proxy for container if host has proxy configured
# Run setup and eval the export statements to make variables global
eval "$(setup_container_proxy)"

# Configure additional tools to use proxy (after variables are exported)
# The variables are now available in the global scope
if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
    # Configure git to use proxy
    if [ -n "$HTTPS_PROXY" ]; then
        git config --global http.proxy "$HTTPS_PROXY" 2>/dev/null || true
        git config --global https.proxy "$HTTPS_PROXY" 2>/dev/null || true
        log_debug "Git proxy configured"
    fi

    # Configure npm to use proxy
    if [ -n "$HTTP_PROXY" ]; then
        npm config set proxy "$HTTP_PROXY" 2>/dev/null || true
        log_debug "NPM HTTP proxy configured"
    fi
    if [ -n "$HTTPS_PROXY" ]; then
        npm config set https-proxy "$HTTPS_PROXY" 2>/dev/null || true
        log_debug "NPM HTTPS proxy configured"
    fi

    # Configure httpx proxy for SearXNG (already done in setup_container_proxy)
    if [ -n "$HTTPX_PROXY" ]; then
        log_debug "HTTPX proxy configured: $HTTPX_PROXY"
    fi
fi

# Start SearXNG in the background
# Since we installed from source, we need to use searxng-run command
log_info "Starting SearXNG..."
# settings.yml should already exist from Dockerfile build
# If volume-mounted config exists, it will override the built-in one
if [ ! -f /etc/searxng/settings.yml ]; then
    log_warn "settings.yml not found, creating from default..."
    # Try to find and copy the default settings
    for pkg_path in /usr/local/lib/python3.* /usr/lib/python3.*; do
        if [ -f "$pkg_path/dist-packages/searxng/settings.yml" ]; then
            cp "$pkg_path/dist-packages/searxng/settings.yml" /etc/searxng/settings.yml
            log_info "Default settings.yml copied from $pkg_path"
            break
        fi
    done
fi

# Log the final configuration file being used
if [ -f /etc/searxng/settings.yml ]; then
    log_info "Using SearXNG configuration from /etc/searxng/settings.yml"
else
    log_error "No settings.yml found! SearXNG may not start properly."
fi

# Dynamically apply settings from environment variables
PROXY_URL="${HOST_HTTPS_PROXY:-$HOST_HTTP_PROXY}"

if [ -f /etc/searxng/settings.yml ]; then
    if python3 -c "
import yaml, sys

with open('/etc/searxng/settings.yml', 'r') as f:
    cfg = yaml.safe_load(f) or {}

# SearXNG always binds to localhost
cfg.setdefault('server', {})['bind_address'] = '127.0.0.1'

# Set outgoing proxy from environment
proxy = '$PROXY_URL'
if proxy:
    cfg.setdefault('outgoing', {})
    cfg['outgoing']['proxies'] = {
        'http': [proxy],
        'https': [proxy],
    }
else:
    cfg.setdefault('outgoing', {})
    cfg['outgoing'].pop('proxies', None)

with open('/etc/searxng/settings.yml', 'w') as f:
    yaml.dump(cfg, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null; then
        log_info "SearXNG bind_address set to: 127.0.0.1"
        if [ -n "$PROXY_URL" ]; then
            log_info "SearXNG outgoing proxy set to: $PROXY_URL"
        fi
    else
        # Fallback: use sed if python yaml not available
        sed -i "s/bind_address:.*/bind_address: \"127.0.0.1\"/" /etc/searxng/settings.yml
        log_info "SearXNG bind_address set to: 127.0.0.1 (sed fallback)"
    fi
fi

# Configure MCP bind address by patching mcp-searxng index.js
# Actual code: app.listen(port, () => { ... })
# We inject host as: app.listen(port, "bind_addr", () => { ... })
configure_mcp_address() {
    local bind_addr="${MCP_BIND_ADDRESS:-127.0.0.1}"

    local mcp_bin
    mcp_bin=$(command -v mcp-searxng 2>/dev/null) || true
    if [ -z "$mcp_bin" ]; then
        log_warn "mcp-searxng not found, skip bind address patch"
        return 0
    fi

    local index_js
    index_js=$(readlink -f "$mcp_bin" 2>/dev/null || echo "$mcp_bin")
    if [ ! -f "$index_js" ]; then
        log_warn "Cannot locate mcp-searxng entry file: $index_js"
        return 0
    fi

    # If binding to 0.0.0.0, no patch needed (Express default is 0.0.0.0)
    if [ "$bind_addr" = "0.0.0.0" ]; then
        # Restore: remove any previously injected host argument
        sed -i -E 's/app\.listen\(port,\s*"[^"]*",/app.listen(port,/' "$index_js"
        log_info "MCP bind address: 0.0.0.0 (Express default, no patch needed)"
        return 0
    fi

    # Restore first: remove any previously injected host argument
    # app.listen(port, "x.x.x.x", ... -> app.listen(port, ...
    sed -i -E 's/app\.listen\(port,\s*"[^"]*",/app.listen(port,/' "$index_js"

    # Patch: app.listen(port, ... -> app.listen(port, "bind_addr", ...
    sed -i -E "s/app\.listen\(port,/app.listen(port, \"$bind_addr\",/" "$index_js"

    # Verify the patch was applied
    if grep -q "app.listen(port, \"$bind_addr\"" "$index_js"; then
        log_info "MCP bind address patched to: $bind_addr"
    else
        log_error "MCP bind address patch FAILED for: $bind_addr"
    fi
}
configure_mcp_address

# Start SearXNG using searxng-run command in background
# Use nohup to ensure it continues running
nohup searxng-run > /var/log/searxng.log 2>&1 &
SEARXNG_PID=$!
log_info "SearXNG started with PID: $SEARXNG_PID"

# Wait for SearXNG to be ready
if ! wait_for_searxng; then
    log_error "SearXNG failed to start. Exiting."
    exit 1
fi

# Verify JSON format support
log_info "Verifying JSON format API support..."
json_test_url="http://localhost:3001/search?q=test&format=json"
if curl -f -s "$json_test_url" > /dev/null 2>&1; then
    # Verify it returns valid JSON
    if curl -f -s "$json_test_url" | python3 -m json.tool > /dev/null 2>&1; then
        log_info "JSON format API verified successfully!"
    else
        log_warn "JSON endpoint responds but may not return valid JSON"
    fi
else
    log_warn "JSON format API may not be properly configured"
fi

# Check if SEARXNG_URL is set, default to localhost if not
if [ -z "$SEARXNG_URL" ]; then
    export SEARXNG_URL="http://localhost:3001"
    log_info "SEARXNG_URL not set, defaulting to $SEARXNG_URL"
fi

# Start MCP server if mcp-searxng is installed
if command -v mcp-searxng &> /dev/null; then
    log_info "Starting mcp-searxng server..."
    log_info "Connecting to SearXNG at: $SEARXNG_URL"

    # Check if HTTP transport is enabled
    if [ -n "$MCP_HTTP_PORT" ]; then
        log_info "MCP HTTP transport enabled on port $MCP_HTTP_PORT"
    fi

    # Start mcp-searxng in foreground
    # This will keep the container running
    exec mcp-searxng &
    MCP_PID=$!

    # Wait for either process
    log_info "Both services are running. Press Ctrl+C to stop."
    wait -n $SEARXNG_PID $MCP_PID

    # If we reach here, one of the processes has exited
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "A service exited unexpectedly with code $exit_code"
    fi
    exit $exit_code
else
    log_error "mcp-searxng not found. Only SearXNG will run."
    log_info "Waiting for SearXNG process..."
    wait $SEARXNG_PID
fi
