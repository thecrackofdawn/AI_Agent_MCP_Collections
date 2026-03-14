# Combined SearXNG + MCP-SearXNG Docker Image

A Docker image that combines [SearXNG](https://github.com/searxng/searxng) (privacy-focused metasearch engine) with [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) (MCP server for SearXNG integration) into a single container.

## Features

- **🔍 SearXNG**: Privacy-respecting metasearch engine on port 8080
- **🤖 MCP Server**: Model Context Protocol server for LLM integration on port 3000
- **📦 Single Container**: Both services running together with automatic health checks
- **🌐 HTTP Transport**: MCP server accessible via HTTP for easy client integration
- **⚡ One-Click Deployment**: Smart deployment script with automatic configuration
- **🔧 Proxy Support**: Automatic detection and configuration with localhost proxy conversion
- **💾 Configuration Management**: Automatic backup and restore of configuration files
- **📊 Health Checks**: Automatic verification of service functionality

## Quick Start

### Method 1: One-Click Deployment (Recommended) ⚡

**The simplest way to deploy - one command completes everything!**

```bash
# Execute directly from GitHub (automatically downloads code)
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash
```

**Why choose one-click deployment?**
- 🚀 **Zero Configuration**: Automatically checks environment, downloads code, builds image, and starts services
- 🔧 **Smart Detection**: Automatically detects and configures proxies (supports localhost proxy auto-conversion)
- 📊 **Health Checks**: Automatically verifies service functionality
- 📝 **Detailed Logging**: Complete operation logs for easy troubleshooting
- 🛡️ **Configuration Backup**: Automatically backs up existing configurations on redeployment
- ⚙️ **Flexible Configuration**: Supports multiple command-line parameters for different scenarios

**Common Command-Line Parameters**:
```bash
./deploy.sh --help          # Show help information
./deploy.sh --clean         # Clean and redeploy (force rebuild)
./deploy.sh --verbose       # Verbose output mode (show debug info)
./deploy.sh --no-proxy      # Disable proxy detection
./deploy.sh --logs          # Show logs immediately after startup
./deploy.sh --quiet         # Quiet mode (errors only)
```

**Service Access After Deployment**:
- 🌐 SearXNG Web UI: http://localhost:8080
- 🔌 MCP Server: http://localhost:3000

📖 **Detailed Documentation**: See [Complete Deployment Guide](DEPLOY_GUIDE.md) for more features, troubleshooting, and advanced usage.

### Method 2: Using Docker Compose

```bash
# Clone or navigate to this directory
cd ~/AI_Agent_MCP_Collections/searxng

# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

### Method 3: Using Docker CLI

```bash
# Build the image
docker build -t searxng-mcp:latest .

# Run the container (no volume mounts required)
docker run -d \
  --name searxng-mcp \
  -p 8080:8080 \
  -p 3000:3000 \
  searxng-mcp:latest
```

## Accessing the Services

### SearXNG Web Interface
```
http://localhost:8080
```

### MCP Server (HTTP Transport)
```
http://localhost:3000/mcp
```

### Quick Test Commands

```bash
# Test SearXNG search (JSON format)
curl "http://localhost:8080/search?q=test&format=json" | jq

# Test MCP health check
curl http://localhost:3000/health

# View SearXNG homepage
curl http://localhost:8080

# Check container status
docker ps | grep searxng-mcp

# Check container health status
docker inspect --format='{{.State.Health.Status}}' searxng-mcp
```

## Deployment Management

### Managing Services Deployed with One-Click Script

If you used the one-click deployment script, services are deployed in `~/.AI_Agent_MCP_Collections/searxng/`:

```bash
# Navigate to deployment directory
cd ~/.AI_Agent_MCP_Collections/searxng

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker-compose logs -f

# Redeploy (using one-click deployment script)
./deploy.sh --clean
```

### Viewing Deployment Logs

```bash
# View latest deployment log
ls -lt ~/.AI_Agent_MCP_Collections/searxng/deploy_*.log | head -1

# View log content
cat ~/.AI_Agent_MCP_Collections/searxng/deploy_20260314_212948.log
```

### Modifying Configuration

```bash
# Edit configuration file
nano ~/.AI_Agent_MCP_Collections/searxng/searxng-config/settings.yml

# Restart services to apply configuration
cd ~/.AI_Agent_MCP_Collections/searxng
docker-compose restart
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SEARXNG_URL` | SearXNG instance URL for MCP server | `http://localhost:8080` | No |
| `MCP_HTTP_PORT` | HTTP transport port for MCP server | `3000` | No |
| `AUTH_USERNAME` | Basic auth username for MCP server | - | No |
| `AUTH_PASSWORD` | Basic auth password for MCP server | - | No |

## MCP Client Configuration

### Claude Desktop Configuration (HTTP Transport - Recommended)

Add to your Claude Desktop `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "searxng": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### Using STDIO Transport (Alternative)

For STDIO mode, you can run the MCP server directly:

```json
{
  "mcpServers": {
    "searxng": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "SEARXNG_URL=http://host.docker.internal:8080",
        "searxng-mcp:latest"
      ]
    }
  }
}
```

**Note**: HTTP mode is recommended as it's simpler and more reliable for most use cases.

### Claude Code CLI Configuration

For Claude Code CLI (claude.ai/code), you can configure MCP servers using command-line tools:

```bash
# Add SearXNG MCP server (HTTP transport)
claude mcp add searxng --url "http://localhost:3000/mcp"

# Or add with STDIO transport
claude mcp add searxng --command "docker" --args "run,-i,--rm,-e,SEARXNG_URL=http://host.docker.internal:8080,searxng-mcp:latest"

# List all configured MCP servers
claude mcp list

# Remove an MCP server
claude mcp remove searxng

# Test MCP server connection
claude mcp test searxng

# Edit MCP configuration file directly
claude mcp edit
```

**Configuration File Location**:
- Linux: `~/.config/claude-code/mcp.json`
- macOS: `~/Library/Application Support/claude-code/mcp.json`
- Windows: `%APPDATA%\claude-code\mcp.json`

Example configuration for HTTP transport:
```json
{
  "mcpServers": {
    "searxng": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

Example configuration for STDIO transport:
```json
{
  "mcpServers": {
    "searxng": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "SEARXNG_URL=http://host.docker.internal:8080",
        "searxng-mcp:latest"
      ]
    }
  }
}
```

## Verification

### Check SearXNG is running
```bash
curl http://localhost:8080
```

### Check MCP server (HTTP endpoint)
```bash
curl http://localhost:3000/mcp
```

### View container logs
```bash
docker logs searxng-mcp
```

### Check health status
```bash
docker inspect --format='{{.State.Health.Status}}' searxng-mcp
```

## Troubleshooting

### One-Click Deployment Related Issues

#### Deployment Script Fails
```bash
# View detailed logs
./deploy.sh --verbose

# View deployment log file
cat ~/.AI_Agent_MCP_Collections/searxng/deploy_*.log
```

#### Port Already in Use
```bash
# Check port usage
lsof -ti:8080
lsof -ti:3000

# Use --clean parameter to automatically stop existing containers
./deploy.sh --clean
```

#### Proxy Issues
```bash
# Skip proxy detection
./deploy.sh --no-proxy

# Or set proxy environment variables
export HTTP_PROXY=http://localhost:7890
export HTTPS_PROXY=http://localhost:7890
./deploy.sh
```

### SearXNG Related Issues

#### SearXNG Not Starting
- Check logs: `docker logs searxng-mcp`
- Verify port 8080 is not already in use: `lsof -ti:8080`
- Ensure configuration files are valid: check `searxng-config/settings.yml`

#### Search Function Issues
- Test API: `curl "http://localhost:8080/search?q=test&format=json"`
- View container logs: `docker logs -f searxng-mcp`
- Check network connection and proxy configuration

### MCP Related Issues

#### MCP Server Not Connecting
- Verify `SEARXNG_URL` is correct
- Check if SearXNG is responding: `curl http://localhost:8080/search?q=test&format=json`
- Test MCP health check: `curl http://localhost:3000/health`
- View container logs: `docker logs -f searxng-mcp`

#### MCP Client Configuration Issues
- See [MCP Client Configuration Guide](MCP_CLIENT_GUIDE.md)
- Verify configuration file path is correct
- Check MCP server URL format

### More Help

- 📘 See the [Deployment Guide](DEPLOY_GUIDE.md) troubleshooting section
- 📗 Check deployment logs: `~/.AI_Agent_MCP_Collections/searxng/deploy_*.log`
- 📙 Submit Issues: [GitHub Issues](https://github.com/thecrackofdawn/AI_Agent_MCP_Collections/issues)



## Building from Source

```bash
# Build the image
docker build -t searxng-mcp:latest .

# Test the build
docker run --rm -p 8080:8080 -p 3000:3000 searxng-mcp:latest
```

## Project Structure

```
.
├── deploy.sh               # One-click deployment script ⭐
├── Dockerfile              # Main image definition
├── docker-compose.yml      # Docker Compose configuration
├── entrypoint.sh           # Custom startup script
├── searxng-config/         # SearXNG configuration directory
│   ├── settings.yml        # SearXNG main configuration
│   └── limiter.toml        # Rate limiting configuration
├── build-with-proxy.sh     # Build script with proxy support
├── build-and-test.sh       # Build and test script
├── README.md              # This file
├── README_EN.md           # English version
├── DEPLOY_GUIDE.md        # Deployment guide ⭐
├── DEPLOY_SUMMARY.md      # Implementation summary
├── QUICKSTART.md          # Quick start guide
├── PROXY_SUPPORT.md       # Proxy configuration details
└── MCP_CLIENT_GUIDE.md    # MCP client configuration guide
```

⭐ = Recommended viewing

## References

### Project Documentation
- 📘 [Deployment Guide](DEPLOY_GUIDE.md) - Detailed one-click deployment instructions
- 📗 [Quick Start](QUICKSTART.md) - Quick start guide
- 📙 [Proxy Support](PROXY_SUPPORT.md) - Proxy configuration details
- 📕 [MCP Client Configuration](MCP_CLIENT_GUIDE.md) - MCP client configuration guide
- 📔 [Implementation Summary](DEPLOY_SUMMARY.md) - One-click deployment script implementation details

### External Resources
- [SearXNG Documentation](https://docs.searxng.org/)
- [mcp-searxng Repository](https://github.com/ihor-sokoliuk/mcp-searxng)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## License

This image combines:
- SearXNG (AGPL-3.0)
- mcp-searxng (MIT)

Please refer to the individual projects for their specific licenses.

---

## Quick Command Reference

### One-Click Deployment
```bash
# Deploy directly from GitHub
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash

# View help
./deploy.sh --help

# Clean and redeploy
./deploy.sh --clean
```

### Service Management
```bash
# View service status
docker ps | grep searxng-mcp

# View service logs
docker logs -f searxng-mcp

# Stop services
docker-compose down

# Restart services
docker-compose restart
```

### Testing and Verification
```bash
# Test SearXNG
curl http://localhost:8080

# Test search API
curl "http://localhost:8080/search?q=test&format=json"

# Test MCP health check
curl http://localhost:3000/health

# Check container health status
docker inspect --format='{{.State.Health.Status}}' searxng-mcp
```

### Configuration Management
```bash
# Edit configuration
nano ~/.AI_Agent_MCP_Collections/searxng/searxng-config/settings.yml

# Backup configuration
cp -r ~/.AI_Agent_MCP_Collections/searxng/searxng-config \
      ~/.AI_Agent_MCP_Collections/searxng/searxng-config.backup

# View deployment logs
ls -lt ~/.AI_Agent_MCP_Collections/searxng/deploy_*.log | head -1
```

---

**🎉 Get Started: One-Click Deploy SearXNG + MCP**

```bash
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash
```

📍 **Access URLs**:
- SearXNG: http://localhost:8080
- MCP Server: http://localhost:3000
