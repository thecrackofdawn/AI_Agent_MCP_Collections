# Combined SearXNG + MCP-SearXNG Docker Image (Ubuntu Base)
# This image provides both SearXNG (privacy-focused metasearch engine)
# and mcp-searxng (MCP server for SearXNG integration) in a single container

FROM ubuntu:24.04

# Build arguments for proxy configuration
ARG BUILD_PROXY_HTTP
ARG BUILD_PROXY_HTTPS
ARG BUILD_PROXY_ALL

LABEL maintainer="shallweqin@gmail.com"
LABEL description="Combined SearXNG web UI with MCP server integration (Ubuntu-based)"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV SEARXNG_URL=http://localhost:3001
ENV MCP_HTTP_PORT=3000

# Configure build-time proxy for all tools (apt, pip, npm, git, curl)
RUN if [ -n "$BUILD_PROXY_HTTP" ] || [ -n "$BUILD_PROXY_HTTPS" ]; then \
        _http="${BUILD_PROXY_HTTP:-$BUILD_PROXY_HTTPS}" && \
        _https="${BUILD_PROXY_HTTPS:-$BUILD_PROXY_HTTP}" && \
        echo "Acquire::http::Proxy \"$_http\";" > /etc/apt/apt.conf.d/99proxy.conf && \
        echo "Acquire::https::Proxy \"$_https\";" >> /etc/apt/apt.conf.d/99proxy.conf && \
        echo "Build proxy configured: http=$_http https=$_https"; \
    else \
        echo "No build proxy configured"; \
    fi

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    build-essential \
    curl \
    wget \
    ca-certificates \
    && rm -f /etc/apt/apt.conf.d/99proxy.conf \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x from NodeSource
RUN if [ -n "$BUILD_PROXY_HTTP" ]; then \
        export http_proxy="$BUILD_PROXY_HTTP" HTTP_PROXY="$BUILD_PROXY_HTTP"; \
    fi && \
    if [ -n "$BUILD_PROXY_HTTPS" ]; then \
        export https_proxy="$BUILD_PROXY_HTTPS" HTTPS_PROXY="$BUILD_PROXY_HTTPS"; \
    fi && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    node --version && npm --version

# Create directories for SearXNG
RUN mkdir -p /etc/searxng /var/cache/searxng

# Configure build-time proxy for git and npm (persistent config)
RUN if [ -n "$BUILD_PROXY_HTTP" ]; then \
        git config --global http.proxy "$BUILD_PROXY_HTTP"; \
        npm config set proxy "$BUILD_PROXY_HTTP"; \
    fi && \
    if [ -n "$BUILD_PROXY_HTTPS" ]; then \
        git config --global https.proxy "$BUILD_PROXY_HTTPS"; \
        npm config set https-proxy "$BUILD_PROXY_HTTPS"; \
    fi

# Install SearXNG from source
WORKDIR /tmp
RUN if [ -n "$BUILD_PROXY_HTTP" ]; then \
        export http_proxy="$BUILD_PROXY_HTTP" HTTP_PROXY="$BUILD_PROXY_HTTP"; \
    fi && \
    if [ -n "$BUILD_PROXY_HTTPS" ]; then \
        export https_proxy="$BUILD_PROXY_HTTPS" HTTPS_PROXY="$BUILD_PROXY_HTTPS"; \
    fi && \
    for i in 1 2 3; do \
        git clone --depth 1 https://github.com/searxng/searxng.git /tmp/searxng && break || sleep 10; \
    done && \
    cd /tmp/searxng && \
    pip3 install --break-system-packages --timeout 120 --retries 5 -r requirements.txt && \
    pip3 install --break-system-packages --timeout 120 --retries 5 . && \
    cd / && \
    rm -rf /tmp/searxng

# Install mcp-searxng globally
RUN if [ -n "$BUILD_PROXY_HTTP" ]; then \
        export http_proxy="$BUILD_PROXY_HTTP" HTTP_PROXY="$BUILD_PROXY_HTTP"; \
    fi && \
    if [ -n "$BUILD_PROXY_HTTPS" ]; then \
        export https_proxy="$BUILD_PROXY_HTTPS" HTTPS_PROXY="$BUILD_PROXY_HTTPS"; \
    fi && \
    npm install -g mcp-searxng@latest

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy SearXNG configuration with JSON format support
COPY searxng-config/settings.yml /etc/searxng/settings.yml
RUN chmod 644 /etc/searxng/settings.yml

# Expose ports
# 3001 - SearXNG web UI and API
# 3000 - MCP HTTP transport
EXPOSE 3001 3000

# Set working directory
WORKDIR /etc/searxng

# Health check - test JSON format API
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f "http://localhost:3001/search?q=test&format=json" || exit 1

# Run entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
