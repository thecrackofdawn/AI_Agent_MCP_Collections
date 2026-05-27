# SearXNG + MCP-SearXNG Docker 镜像

[English](README_EN.md) | 简体中文

将 [SearXNG](https://github.com/searxng/searxng)（隐私元搜索引擎）与 [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng)（MCP 服务器）整合到单个容器中。

## 快速开始

```bash
# 一键部署（推荐）
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash

# 或手动部署
git clone -b main --depth 1 https://github.com/thecrackofdawn/AI_Agent_MCP_Collections.git
cd AI_Agent_MCP_Collections/searxng
docker compose up -d
```

部署完成后访问：
- SearXNG Web UI: http://localhost:3001
- MCP 服务器: http://localhost:3000

## deploy.sh 参数

```bash
./deploy.sh --clean              # 清理旧部署并重新构建
./deploy.sh --bind 0.0.0.0       # 绑定到所有网卡（默认 127.0.0.1 仅本地）
./deploy.sh --no-proxy           # 禁用代理检测
./deploy.sh --verbose            # 详细输出
./deploy.sh --logs               # 启动后显示日志
./deploy.sh --skip-health-check  # 跳过健康检查
```

## 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `SEARXNG_URL` | SearXNG 实例 URL | `http://localhost:3001` |
| `MCP_HTTP_PORT` | MCP HTTP 端口 | `3000` |
| `HTTP_PROXY` / `HTTPS_PROXY` | 代理地址，构建和运行时自动使用 | - |

## MCP 客户端配置

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

## 测试

```bash
# SearXNG 搜索
curl "http://localhost:3001/search?q=test&format=json"

# MCP 健康检查
curl http://localhost:3000/health
```

## 服务管理

```bash
docker compose logs -f     # 查看日志
docker compose restart      # 重启
docker compose down         # 停止
docker compose up -d        # 启动
```

配置文件位于 `searxng-config/settings.yml`，修改后执行 `docker compose restart` 生效。

## 项目结构

```
├── deploy.sh             # 一键部署脚本
├── Dockerfile            # 镜像定义
├── docker-compose.yml    # Compose 配置（host 网络模式）
├── entrypoint.sh         # 启动脚本
├── searxng-config/       # SearXNG 配置
│   ├── settings.yml
│   └── limiter.toml
└── build-with-proxy.sh   # 带代理的构建脚本
```

## 故障排除

```bash
# 查看容器日志
docker logs -f searxng-mcp

# 端口占用时清理重建
./deploy.sh --clean

# 代理导致构建失败时跳过代理
./deploy.sh --no-proxy
```

## 许可证

- SearXNG (AGPL-3.0)
- mcp-searxng (MIT)
