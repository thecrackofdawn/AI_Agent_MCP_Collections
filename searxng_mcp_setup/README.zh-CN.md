# SearXNG + MCP-SearXNG Docker 镜像

一个将 [SearXNG](https://github.com/searxng/searxng)（注重隐私的元搜索引擎）与 [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng)（用于 SearXNG 集成的 MCP 服务器）组合到单个容器中的 Docker 镜像。

## 功能特性

- **SearXNG**：运行在 8080 端口的注重隐私的元搜索引擎
- **MCP 服务器**：运行在 3000 端口的模型上下文协议服务器，用于 LLM 集成
- **单容器方案**：两个服务协同运行，配备自动健康检查
- **HTTP 传输**：MCP 服务器可通过 HTTP 访问，便于客户端集成

## 快速开始

### 使用 Docker Compose（推荐）

```bash
# 克隆或进入此目录
cd /home/cd/Documents/notes/LLM/searxng_mcp_setup

# 构建并启动容器
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止容器
docker-compose down
```

### 使用 Docker CLI

```bash
# 构建镜像
docker build -t searxng-mcp:latest .

# 运行容器（无需挂载卷）
docker run -d \
  --name searxng-mcp \
  -p 8080:8080 \
  -p 3000:3000 \
  searxng-mcp:latest
```

## 访问服务

### SearXNG Web 界面
```
http://localhost:8080
```

### MCP 服务器（HTTP 传输）
```
http://localhost:3000/mcp
```

## 配置

### 环境变量

| 变量 | 描述 | 默认值 | 必需 |
|----------|-------------|---------|----------|
| `SEARXNG_URL` | MCP 服务器的 SearXNG 实例 URL | `http://localhost:8080` | 否 |
| `MCP_HTTP_PORT` | MCP 服务器的 HTTP 传输端口 | `3000` | 否 |
| `AUTH_USERNAME` | MCP 服务器的基本认证用户名 | - | 否 |
| `AUTH_PASSWORD` | MCP 服务器的基本认证密码 | - | 否 |

## MCP 客户端配置

### Claude Desktop 配置（HTTP 传输 - 推荐）

在您的 Claude Desktop `claude_desktop_config.json` 中添加：

```json
{
  "mcpServers": {
    "searxng": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### 使用 STDIO 传输（备选方案）

对于 STDIO 模式，您可以直接运行 MCP 服务器：

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

**注意**：推荐使用 HTTP 模式，因为它更简单且在大多数用例中更可靠。

### Claude Code CLI 配置

对于 Claude Code CLI (claude.ai/code)，您可以使用命令行工具配置 MCP 服务器：

```bash
# 添加 SearXNG MCP 服务器（HTTP 传输）
claude mcp add searxng --url "http://localhost:3000/mcp"

# 或者使用 STDIO 传输添加
claude mcp add searxng --command "docker" --args "run,-i,--rm,-e,SEARXNG_URL=http://host.docker.internal:8080,searxng-mcp:latest"

# 列出所有已配置的 MCP 服务器
claude mcp list

# 删除 MCP 服务器
claude mcp remove searxng

# 测试 MCP 服务器连接
claude mcp test searxng

# 直接编辑 MCP 配置文件
claude mcp edit
```

**配置文件位置**：
- Linux: `~/.config/claude-code/mcp.json`
- macOS: `~/Library/Application Support/claude-code/mcp.json`
- Windows: `%APPDATA%\claude-code\mcp.json`

HTTP 传输配置示例：
```json
{
  "mcpServers": {
    "searxng": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

STDIO 传输配置示例：
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

## 验证

### 检查 SearXNG 是否运行
```bash
curl http://localhost:8080
```

### 检查 MCP 服务器（HTTP 端点）
```bash
curl http://localhost:3000/mcp
```

### 查看容器日志
```bash
docker logs searxng-mcp
```

### 检查健康状态
```bash
docker inspect --format='{{.State.Health.Status}}' searxng-mcp
```

## 故障排查

### SearXNG 无法启动
- 检查日志：`docker logs searxng-mcp`
- 验证 8080 端口未被占用
- 确保 `/etc/searxng` 中的配置文件有效

### MCP 服务器无法连接
- 验证 `SEARXNG_URL` 是否正确
- 检查 SearXNG 是否响应：`curl http://localhost:8080/search?q=test&format=json`
- 测试 MCP 服务器端点：`curl http://localhost:3000/mcp`
- 查看日志中的 MCP 服务器错误

## 从源码构建

```bash
# 构建镜像
docker build -t searxng-mcp:latest .

# 测试构建
docker run --rm -p 8080:8080 -p 3000:3000 searxng-mcp:latest
```

## 项目结构

```
.
├── Dockerfile              # 主镜像定义
├── docker-compose.yml      # Docker Compose 配置
├── entrypoint.sh           # 自定义启动脚本
├── README.md               # 英文文档
└── README.zh-CN.md         # 中文文档（本文件）
```

## 参考资料

- [SearXNG 官方文档](https://docs.searxng.org/)
- [mcp-searxng 仓库](https://github.com/ihor-sokoliuk/mcp-searxng)
- [模型上下文协议](https://modelcontextprotocol.io/)

## 许可证

本镜像组合了以下项目：
- SearXNG (AGPL-3.0)
- mcp-searxng (MIT)

请参考各个项目以了解其具体的许可证。
