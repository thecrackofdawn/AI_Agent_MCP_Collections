# SearXNG + MCP-SearXNG Docker Image

简体中文 | [English](README_EN.md)

A Docker image combining [SearXNG](https://github.com/searxng/searxng) (privacy metasearch engine) with [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) (MCP server) in a single container.

## Quick Start

```bash
# One-click deploy (recommended)
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash

# Or deploy manually
git clone -b main --depth 1 https://github.com/thecrackofdawn/AI_Agent_MCP_Collections.git
cd AI_Agent_MCP_Collections/searxng
docker compose up -d
```

After deployment:
- SearXNG Web UI: http://localhost:3001
- MCP Server: http://localhost:3000

## deploy.sh Options

```bash
./deploy.sh --clean              # Clean old deployment and rebuild
./deploy.sh --bind 0.0.0.0       # Bind to all interfaces (default: 127.0.0.1)
./deploy.sh --no-proxy           # Disable proxy detection
./deploy.sh --verbose            # Verbose output
./deploy.sh --logs               # Show logs after startup
./deploy.sh --skip-health-check  # Skip health check
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SEARXNG_URL` | SearXNG instance URL | `http://localhost:3001` |
| `MCP_HTTP_PORT` | MCP HTTP port | `3000` |
| `HTTP_PROXY` / `HTTPS_PROXY` | Proxy address, auto-used during build and runtime | - |

## MCP Client Configuration

### Claude Desktop

```json
{
  "mcpServers": {
    "searxng": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### Claude Code CLI

```bash
claude mcp add searxng --url "http://localhost:3000/mcp"
```

## Testing

```bash
# SearXNG search
curl "http://localhost:3001/search?q=test&format=json"

# MCP health check
curl http://localhost:3000/health
```

## Service Management

```bash
docker compose logs -f     # View logs
docker compose restart      # Restart
docker compose down         # Stop
docker compose up -d        # Start
```

Configuration is at `searxng-config/settings.yml`. Run `docker compose restart` after changes.

## Project Structure

```
├── deploy.sh             # One-click deployment script
├── Dockerfile            # Image definition
├── docker-compose.yml    # Compose config (host network mode)
├── entrypoint.sh         # Startup script
├── searxng-config/       # SearXNG configuration
│   ├── settings.yml
│   └── limiter.toml
└── build-with-proxy.sh   # Build script with proxy support
```

## Troubleshooting

```bash
# View container logs
docker logs -f searxng-mcp

# Clean and rebuild when ports are occupied
./deploy.sh --clean

# Skip proxy when it causes build failures
./deploy.sh --no-proxy
```

## License

- SearXNG (AGPL-3.0)
- mcp-searxng (MIT)
