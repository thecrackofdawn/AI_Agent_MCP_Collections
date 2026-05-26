# AI Agent MCP Collections

收集实用的 MCP（Model Context Protocol）工具及其 Docker 部署方案，帮助快速搭建 AI Agent 所需的工具链。

每个工具都提供开箱即用的 Docker 部署配置和一键部署脚本，支持代理网络环境。

## MCP 工具导航

| 工具 | 说明 | 部署文档 |
|------|------|----------|
| [SearXNG + MCP](searxng/) | 注重隐私的元搜索引擎 + MCP 服务器，支持 LLM 调用搜索能力 | [部署指南](searxng/README.md) |

## 快速部署

进入对应工具目录，按照其 README 中的说明进行部署即可。通常支持两种方式：

**一键部署（推荐）**：使用各工具目录下的 `deploy.sh` 脚本，自动完成环境检查、镜像构建和服务启动。

**Docker Compose 部署**：在工具目录下执行 `docker-compose up -d`。

## 项目结构

```
.
├── searxng/          # SearXNG 元搜索引擎 + MCP 服务器
│   ├── README.md     # 部署文档
│   ├── deploy.sh     # 一键部署脚本
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── ...
└── README.md         # 本文件
```
