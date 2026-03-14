# SearXNG + MCP-SearXNG 联合 Docker 镜像

[English](README_EN.md) | 简体中文

一个将 [SearXNG](https://github.com/searxng/searxng)（注重隐私的元搜索引擎）与 [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng)（用于 SearXNG 集成的 MCP 服务器）组合到单个容器中的 Docker 镜像。

## 功能特性

- **🔍 SearXNG**：运行在 8080 端口的注重隐私的元搜索引擎
- **🤖 MCP 服务器**：运行在 3000 端口的模型上下文协议服务器，用于 LLM 集成
- **📦 单容器**：两个服务一起运行，具有自动健康检查
- **🌐 HTTP 传输**：MCP 服务器可通过 HTTP 访问，便于客户端集成
- **⚡ 一键部署**：智能部署脚本，自动完成所有配置
- **🔧 代理支持**：自动检测并配置代理，支持 localhost 代理自动转换
- **💾 配置管理**：自动备份和恢复配置文件
- **📊 健康检查**：自动验证服务功能是否正常

## 快速开始

### 方式一：一键部署（推荐）⚡

**最简单的部署方式，一行命令完成所有操作！**

```bash
# 从 GitHub 直接执行（会自动下载代码并部署）
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash
```

**为什么选择一键部署？**
- 🚀 **零配置**：自动检查环境、下载代码、构建镜像、启动服务
- 🔧 **智能检测**：自动检测并配置代理（支持 localhost 代理自动转换）
- 📊 **健康检查**：自动验证服务功能是否正常
- 📝 **详细日志**：完整的操作日志，方便问题排查
- 🛡️ **配置备份**：重新部署时自动备份现有配置
- ⚙️ **灵活配置**：支持多种命令行参数适应不同场景

**常用命令行参数**：
```bash
./deploy.sh --help          # 显示帮助信息
./deploy.sh --clean         # 清理并重新部署（强制重建）
./deploy.sh --verbose       # 详细输出模式（查看调试信息）
./deploy.sh --no-proxy      # 禁用代理检测
./deploy.sh --logs          # 启动后直接显示日志
./deploy.sh --quiet         # 静默模式（只显示错误）
```

**部署后的服务访问**：
- 🌐 SearXNG Web UI: http://localhost:8080
- 🔌 MCP 服务器: http://localhost:3000

📖 **详细文档**：查看 [完整部署指南](DEPLOY_GUIDE.md) 了解更多功能、故障排查和高级用法。

### 使用 Docker Compose

```bash
# 克隆或导航到此目录
cd ~/AI_Agent_MCP_Collections/searxng

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

### 快速测试命令

```bash
# 测试 SearXNG 搜索（JSON 格式）
curl "http://localhost:8080/search?q=test&format=json" | jq

# 测试 MCP 健康检查
curl http://localhost:3000/health

# 查看 SearXNG 主页
curl http://localhost:8080

# 查看容器状态
docker ps | grep searxng-mcp

# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' searxng-mcp
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

将以下内容添加到您的 Claude Desktop `claude_desktop_config.json`：

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

**注意**：对于大多数用例，推荐使用 HTTP 模式，因为它更简单且更可靠。

### Claude Code CLI 配置

对于 Claude Code CLI (claude.ai/code)，您可以使用命令行工具配置 MCP 服务器：

```bash
# 添加 SearXNG MCP 服务器（HTTP 传输）
claude mcp add searxng --url "http://localhost:3000/mcp"

# 或使用 STDIO 传输添加
claude mcp add searxng --command "docker" --args "run,-i,--rm,-e,SEARXNG_URL=http://host.docker.internal:8080,searxng-mcp:latest"

# 列出所有配置的 MCP 服务器
claude mcp list

# 移除 MCP 服务器
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

## 部署后管理

### 使用一键部署脚本管理的服务

如果您使用了一键部署脚本，服务会部署到 `~/.AI_Agent_MCP_Collections/searxng/` 目录：

```bash
# 进入部署目录
cd ~/.AI_Agent_MCP_Collections/searxng

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 重新部署（使用一键部署脚本）
./deploy.sh --clean
```

### 查看部署日志

```bash
# 查看最新的部署日志
ls -lt ~/.AI_Agent_MCP_Collections/searxng/deploy_*.log | head -1

# 查看日志内容
cat ~/.AI_Agent_MCP_Collections/searxng/deploy_20260314_212948.log
```

### 修改配置

```bash
# 编辑配置文件
nano ~/.AI_Agent_MCP_Collections/searxng/searxng-config/settings.yml

# 重启服务使配置生效
cd ~/.AI_Agent_MCP_Collections/searxng
docker-compose restart
```

## 验证

### 检查 SearXNG 是否正在运行
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

## 故障排除

### 一键部署相关

#### 部署脚本失败
```bash
# 查看详细日志
./deploy.sh --verbose

# 查看部署日志文件
cat ~/.AI_Agent_MCP_Collections/searxng/deploy_*.log
```

#### 端口被占用
```bash
# 检查端口占用
lsof -ti:8080
lsof -ti:3000

# 使用 --clean 参数自动停止现有容器
./deploy.sh --clean
```

#### 代理问题
```bash
# 跳过代理检测
./deploy.sh --no-proxy

# 或设置代理环境变量
export HTTP_PROXY=http://localhost:7890
export HTTPS_PROXY=http://localhost:7890
./deploy.sh
```

### SearXNG 相关

#### SearXNG 无法启动
- 检查日志：`docker logs searxng-mcp`
- 验证 8080 端口未被占用：`lsof -ti:8080`
- 确保配置文件有效：检查 `searxng-config/settings.yml`

#### 搜索功能异常
- 测试 API：`curl "http://localhost:8080/search?q=test&format=json"`
- 查看容器日志：`docker logs -f searxng-mcp`
- 检查网络连接和代理配置

### MCP 相关

#### MCP 服务器无法连接
- 验证 `SEARXNG_URL` 是否正确
- 检查 SearXNG 是否响应：`curl http://localhost:8080/search?q=test&format=json`
- 测试 MCP 健康检查：`curl http://localhost:3000/health`
- 查看容器日志：`docker logs -f searxng-mcp`

#### MCP 客户端配置问题
- 查看 [MCP 客户端配置指南](MCP_CLIENT_GUIDE.md)
- 确认配置文件路径正确
- 检查 MCP 服务器 URL 格式

### 更多帮助

- 📘 查看 [部署指南](DEPLOY_GUIDE.md) 的故障排除章节
- 📗 查看部署日志：`~/.AI_Agent_MCP_Collections/searxng/deploy_*.log`
- 📙 提交 Issue：[GitHub Issues](https://github.com/thecrackofdawn/AI_Agent_MCP_Collections/issues)

## 从源代码构建

```bash
# 构建镜像
docker build -t searxng-mcp:latest .

# 测试构建
docker run --rm -p 8080:8080 -p 3000:3000 searxng-mcp:latest
```

## 项目结构

```
.
├── deploy.sh               # 一键部署脚本 ⭐
├── Dockerfile              # 主镜像定义
├── docker-compose.yml      # Docker Compose 配置
├── entrypoint.sh           # 自定义启动脚本
├── searxng-config/         # SearXNG 配置目录
│   ├── settings.yml        # SearXNG 主配置
│   └── limiter.toml        # 速率限制配置
├── build-with-proxy.sh     # 带代理的构建脚本
├── build-and-test.sh       # 构建和测试脚本
├── README.md              # 本文件
├── DEPLOY_GUIDE.md        # 部署指南 ⭐
├── DEPLOY_SUMMARY.md      # 实现总结
├── QUICKSTART.md          # 快速开始指南
├── PROXY_SUPPORT.md       # 代理配置详解
└── MCP_CLIENT_GUIDE.md    # MCP 客户端配置指南
```

⭐ = 推荐查看

## 参考资料

### 项目文档
- 📘 [部署指南](DEPLOY_GUIDE.md) - 详细的一键部署使用说明
- 📗 [快速开始](QUICKSTART.md) - 快速入门指南
- 📙 [代理配置](PROXY_SUPPORT.md) - 代理设置详解
- 📕 [MCP 客户端配置](MCP_CLIENT_GUIDE.md) - MCP 客户端配置指南
- 📔 [实现总结](DEPLOY_SUMMARY.md) - 一键部署脚本实现细节

### 外部资源
- [SearXNG 文档](https://docs.searxng.org/)
- [mcp-searxng 仓库](https://github.com/ihor-sokoliuk/mcp-searxng)
- [模型上下文协议](https://modelcontextprotocol.io/)

## 许可证

本镜像组合了：
- SearXNG (AGPL-3.0)
- mcp-searxng (MIT)

请参阅各个项目以了解其具体许可证。

---

## 快速命令参考

### 一键部署
```bash
# 从 GitHub 直接部署
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash

# 查看帮助
./deploy.sh --help

# 清理并重新部署
./deploy.sh --clean
```

### 服务管理
```bash
# 查看服务状态
docker ps | grep searxng-mcp

# 查看服务日志
docker logs -f searxng-mcp

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
```

### 测试和验证
```bash
# 测试 SearXNG
curl http://localhost:8080

# 测试搜索 API
curl "http://localhost:8080/search?q=test&format=json"

# 测试 MCP 健康检查
curl http://localhost:3000/health

# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' searxng-mcp
```

### 配置管理
```bash
# 编辑配置
nano ~/.AI_Agent_MCP_Collections/searxng/searxng-config/settings.yml

# 备份配置
cp -r ~/.AI_Agent_MCP_Collections/searxng/searxng-config \
      ~/.AI_Agent_MCP_Collections/searxng/searxng-config.backup

# 查看部署日志
ls -lt ~/.AI_Agent_MCP_Collections/searxng/deploy_*.log | head -1
```

---

**🎉 开始使用：一键部署 SearXNG + MCP**

```bash
curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash
```

📍 **访问地址**：
- SearXNG: http://localhost:8080
- MCP 服务器: http://localhost:3000
