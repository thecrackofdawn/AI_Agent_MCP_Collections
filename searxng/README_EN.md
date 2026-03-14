# Combined SearXNG + MCP-SearXNG Docker Image

A Docker image that combines [SearXNG](https://github.com/searxng/searxng) (privacy-focused metasearch engine) with [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) (MCP server for SearXNG integration) into a single container.

## Features

- **SearXNG**: Privacy-respecting metasearch engine on port 8080
- **MCP Server**: Model Context Protocol server for LLM integration on port 3000
- **Single Container**: Both services running together with automatic health checks
- **HTTP Transport**: MCP server accessible via HTTP for easy client integration

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone or navigate to this directory
cd /home/cd/Documents/notes/LLM/searxng_mcp_setup

# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

### Using Docker CLI

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

### SearXNG not starting
- Check logs: `docker logs searxng-mcp`
- Verify port 8080 is not already in use
- Ensure configuration files in `/etc/searxng` are valid

### MCP server not connecting
- Verify `SEARXNG_URL` is correct
- Check if SearXNG is responding: `curl http://localhost:8080/search?q=test&format=json`
- Test MCP server endpoint: `curl http://localhost:3000/mcp`
- Review logs for MCP server errors



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
├── Dockerfile              # Main image definition
├── docker-compose.yml      # Docker Compose configuration
├── entrypoint.sh           # Custom startup script
└── README.md              # This file
```

## References

- [SearXNG Documentation](https://docs.searxng.org/)
- [mcp-searxng Repository](https://github.com/ihor-sokoliuk/mcp-searxng)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## License

This image combines:
- SearXNG (AGPL-3.0)
- mcp-searxng (MIT)

Please refer to the individual projects for their specific licenses.
