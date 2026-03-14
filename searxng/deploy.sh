#!/bin/bash
set -e

#############################################
# SearXNG + MCP 一键部署脚本
# 支持从 GitHub 直接执行或本地执行
#############################################

# 版本信息
VERSION="1.0.0"
REPO_URL="https://github.com/thecrackofdawn/AI_Agent_MCP_Collections.git"
REPO_BRANCH="main"

# 目录常量
DEPLOY_DIR="${HOME}/.AI_Agent_MCP_Collections/searxng"
TEMP_DIR=$(mktemp -d)
SCRIPT_NAME="$(basename "$0")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
VERBOSE=false
QUIET=false
CLEAN_DEPLOY=false
NO_PROXY=false
SKIP_HEALTH_CHECK=false
SHOW_LOGS=false
CONFIG_ONLY=false

# 代理变量
PROXY_HTTP=""
PROXY_HTTPS=""
BUILD_PROXY_HTTP=""
BUILD_PROXY_HTTPS=""

# 临时构建目录（会被动态设置）
TEMP_BUILD_DIR=""

# 日志文件
LOG_FILE=""

#############################################
# 日志函数
#############################################

log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
    log_to_file "[INFO] $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
    log_to_file "[WARN] $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    log_to_file "[ERROR] $1"
}

log_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[SUCCESS]${NC} ✓ $1"
    fi
    log_to_file "[SUCCESS] $1"
}

log_step() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}[STEP]${NC} $1"
    fi
    log_to_file "[STEP] $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
    log_to_file "[DEBUG] $1"
}

log_to_file() {
    if [ -n "$LOG_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

#############################################
# 显示函数
#############################################

show_welcome() {
    if [ "$QUIET" = false ]; then
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}         ${GREEN}SearXNG + MCP 一键部署脚本${NC}              ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}         ${GREEN}版本: ${VERSION}${NC}                              ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo
    fi
}

show_separator() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

show_help() {
    cat << EOF
用法: $SCRIPT_NAME [选项]

选项:
  -h, --help              显示此帮助信息
  -c, --clean             强制清理旧部署并重新部署
  --no-proxy              禁用代理检测
  --skip-health-check     跳过健康检查
  -v, --verbose           详细输出模式
  -q, --quiet             静默模式（只显示错误）
  --logs                  启动后直接显示日志
  --config-only           仅生成配置文件

示例:
  # 从 GitHub 直接执行（会自动下载代码）
  curl -sSL https://raw.githubusercontent.com/thecrackofdawn/AI_Agent_MCP_Collections/main/searxng/deploy.sh | bash

  # 基础部署
  ./$SCRIPT_NAME

  # 清理并重新部署
  ./$SCRIPT_NAME --clean

  # 详细模式
  ./$SCRIPT_NAME --verbose

  # 无代理模式
  ./$SCRIPT_NAME --no-proxy

  # 启动后查看日志
  ./$SCRIPT_NAME --logs

更多信息请访问: $REPO_URL
EOF
}

#############################################
# 目录和环境检查
#############################################

check_project_directory() {
    log_info "正在检查当前目录..."

    if [ -f "docker-compose.yml" ] && [ -f "Dockerfile" ] && [ -f "entrypoint.sh" ]; then
        log_success "已在项目目录中，跳过下载"
        TEMP_BUILD_DIR="$(pwd)"
        DEPLOY_DIR="$(pwd)"
        return 0
    else
        log_warn "当前目录不包含部署文件"
        return 1
    fi
}

setup_deployment_directory() {
    log_info "设置部署目录: $DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR"
    log_success "部署目录已创建"
}

download_and_build() {
    if check_project_directory; then
        return 0
    fi

    log_info "正在从 GitHub 下载..."
    log_verbose "克隆仓库到临时目录: $TEMP_DIR"

    # 检查 git 是否可用
    if ! command -v git &> /dev/null; then
        log_error "未找到 git 命令"
        log_error "请先安装 git: sudo apt-get install git"
        exit 1
    fi

    # 克隆仓库到临时目录
    if ! git clone -b "$REPO_BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
        log_error "从 GitHub 克隆仓库失败"
        log_error "请检查网络连接或手动下载仓库"
        exit 1
    fi

    log_success "仓库克隆成功"
    TEMP_BUILD_DIR="$TEMP_DIR/repo/searxng"

    # 验证目录存在
    if [ ! -d "$TEMP_BUILD_DIR" ]; then
        log_error "下载的仓库中未找到 searxng 目录"
        exit 1
    fi

    cd "$TEMP_BUILD_DIR"
    log_verbose "工作目录: $(pwd)"
}

copy_runtime_files() {
    if check_project_directory; then
        log_verbose "在项目目录中，跳过文件拷贝"
        return 0
    fi

    setup_deployment_directory

    log_info "正在拷贝运行时文件..."

    # 拷贝 docker-compose.yml
    if [ -f "$TEMP_BUILD_DIR/docker-compose.yml" ]; then
        cp "$TEMP_BUILD_DIR/docker-compose.yml" "$DEPLOY_DIR/"
        log_verbose "已拷贝: docker-compose.yml"
    else
        log_error "未找到 docker-compose.yml"
        exit 1
    fi

    # 拷贝配置目录
    if [ -d "$TEMP_BUILD_DIR/searxng-config" ]; then
        cp -r "$TEMP_BUILD_DIR/searxng-config" "$DEPLOY_DIR/"
        log_verbose "已拷贝: searxng-config/"
    else
        log_error "未找到 searxng-config 目录"
        exit 1
    fi

    log_success "运行时文件已拷贝到: $DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    log_verbose "切换到部署目录: $(pwd)"
}

cleanup_temp_dir() {
    if [ "$TEMP_BUILD_DIR" != "$(pwd)" ] && [ -n "$TEMP_BUILD_DIR" ]; then
        log_info "清理临时文件..."
        rm -rf "$TEMP_DIR"
        log_success "临时目录已删除"
    fi
}

#############################################
# 环境检查
#############################################

check_docker() {
    log_step "检查 Docker 环境"

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或未在 PATH 中"
        log_error "请安装 Docker: https://docs.docker.com/get-docker/"
        exit 2
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker 守护进程未运行"
        log_error "请启动 Docker: sudo systemctl start docker"
        exit 2
    fi

    log_success "Docker 已安装并运行"

    # 检查 Docker Compose
    if docker compose version &> /dev/null; then
        log_verbose "Docker Compose (插件) 可用"
    elif docker-compose --version &> /dev/null; then
        log_verbose "Docker Compose (独立版) 可用"
    else
        log_error "未找到 Docker Compose"
        log_error "请安装 Docker Compose: https://docs.docker.com/compose/install/"
        exit 2
    fi

    log_success "Docker Compose 可用"
}

check_ports() {
    log_step "检查端口占用"

    local ports=("8080" "3000")
    local port_in_use=()

    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an 2>/dev/null | grep ":$port " | grep LISTEN >/dev/null; then
            port_in_use+=($port)
        fi
    done

    if [ ${#port_in_use[@]} -gt 0 ]; then
        log_warn "以下端口已被占用: ${port_in_use[*]}"

        if [ "$CLEAN_DEPLOY" = true ]; then
            log_info "由于 --clean 参数，尝试停止现有容器..."
            stop_existing_containers
        else
            echo
            read -p "是否停止现有容器并继续? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                stop_existing_containers
            else
                log_error "部署已取消"
                exit 3
            fi
        fi
    fi

    log_success "端口 8080 和 3000 可用"
}

stop_existing_containers() {
    log_info "正在停止现有容器..."

    # 尝试使用 docker-compose 停止
    if [ -f "$DEPLOY_DIR/docker-compose.yml" ]; then
        cd "$DEPLOY_DIR"
        docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
    fi

    # 强制停止已知的容器
    docker stop searxng-mcp 2>/dev/null || true
    docker rm searxng-mcp 2>/dev/null || true

    log_success "现有容器已停止"
}

check_system_resources() {
    log_step "检查系统资源"

    # 检查磁盘空间（至少需要 2GB）
    local available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available_space" -lt 2 ]; then
        log_warn "磁盘空间不足 2GB，可能影响构建"
    else
        log_verbose "可用磁盘空间: ${available_space}GB"
    fi

    # 检查内存（至少需要 2GB）
    local total_memory=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_memory" -lt 2048 ]; then
        log_warn "内存不足 2GB，可能影响性能"
    else
        log_verbose "可用内存: $((total_memory / 1024))GB"
    fi
}

#############################################
# 代理配置
#############################################

detect_proxy() {
    if [ "$NO_PROXY" = true ]; then
        log_info "代理检测已禁用 (--no-proxy)"
        return 1
    fi

    log_step "检测代理配置"

    # 检查常见的代理环境变量
    if [ -n "$HTTP_PROXY" ] || [ -n "$http_proxy" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$https_proxy" ]; then
        # 使用第一个可用的代理
        PROXY_HTTP="${HTTP_PROXY:-$http_proxy}"
        PROXY_HTTPS="${HTTPS_PROXY:-$https_proxy:-$PROXY_HTTP}"

        log_info "检测到代理配置:"
        log_info "  HTTP_PROXY=$PROXY_HTTP"
        log_info "  HTTPS_PROXY=$PROXY_HTTPS"

        # 转换 localhost/127.0.0.1 为 Docker 主机网关地址
        if echo "$PROXY_HTTP" | grep -qE 'https?://(localhost|127\.0\.0\.1):'; then
            log_info "检测到 localhost 代理，将自动转换为 Docker 网关地址"
        fi

        return 0
    else
        log_info "未检测到代理配置"
        return 1
    fi
}

convert_proxy_for_build() {
    if [ -z "$PROXY_HTTP" ]; then
        return 1
    fi

    log_info "转换代理地址用于 Docker 构建..."

    # 构建时：localhost → 172.17.0.1 (Docker bridge)
    BUILD_PROXY_HTTP=$(echo "$PROXY_HTTP" | sed 's|://localhost:|://172.17.0.1:|' | sed 's|://127.0.0.1:|://172.17.0.1:|')
    BUILD_PROXY_HTTPS=$(echo "$PROXY_HTTPS" | sed 's|://localhost:|://172.17.0.1:|' | sed 's|://127.0.0.1:|://172.17.0.1:|')

    log_verbose "构建代理:"
    log_verbose "  HTTP_PROXY=$BUILD_PROXY_HTTP"
    log_verbose "  HTTPS_PROXY=$BUILD_PROXY_HTTPS"

    return 0
}

apply_proxy_settings() {
    if [ -z "$BUILD_PROXY_HTTP" ]; then
        return 0
    fi

    log_info "应用代理设置到 Docker 构建..."

    # 导出构建时代代理
    export BUILD_PROXY_HTTP
    export BUILD_PROXY_HTTPS

    return 0
}

verify_proxy_connection() {
    if [ -z "$PROXY_HTTP" ]; then
        return 0
    fi

    log_step "验证代理连接"

    if curl -x "$PROXY_HTTP" -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
        log_success "代理连接正常"
        return 0
    else
        log_warn "代理连接测试失败，但将继续尝试构建"
        return 1
    fi
}

#############################################
# 配置管理
#############################################

setup_configs() {
    log_step "检查配置文件"

    local config_dir="$DEPLOY_DIR/searxng-config"

    if [ ! -d "$config_dir" ]; then
        log_info "创建配置目录..."
        mkdir -p "$config_dir"
    fi

    # 检查或创建 settings.yml
    if [ ! -f "$config_dir/settings.yml" ]; then
        if [ -f "$TEMP_BUILD_DIR/settings.yml.example" ]; then
            log_info "从示例文件创建配置..."
            cp "$TEMP_BUILD_DIR/settings.yml.example" "$config_dir/settings.yml"
            log_success "已创建配置文件: settings.yml"
        elif [ -f "$config_dir/settings.yml.example" ]; then
            log_info "从示例文件创建配置..."
            cp "$config_dir/settings.yml.example" "$config_dir/settings.yml"
            log_success "已创建配置文件: settings.yml"
        else
            log_warn "未找到 settings.yml.example，将使用默认配置"
        fi
    else
        log_verbose "配置文件已存在: settings.yml"
    fi

    # 检查 limiter.toml
    if [ ! -f "$config_dir/limiter.toml" ] && [ -f "$TEMP_BUILD_DIR/searxng-config/limiter.toml" ]; then
        cp "$TEMP_BUILD_DIR/searxng-config/limiter.toml" "$config_dir/"
        log_verbose "已创建: limiter.toml"
    fi

    log_success "配置文件检查完成"
}

backup_configs() {
    local config_dir="$DEPLOY_DIR/searxng-config"
    local backup_dir="${config_dir}.backup.$(date +%Y%m%d_%H%M%S)"

    if [ -d "$config_dir" ]; then
        log_info "备份现有配置到: $backup_dir"
        cp -r "$config_dir" "$backup_dir"
        log_success "配置已备份"
    fi
}

#############################################
# 构建和部署
#############################################

build_image() {
    log_step "构建 Docker 镜像"

    local build_args=""
    local build_cmd="docker build"

    # 添加代理参数
    if [ -n "$BUILD_PROXY_HTTP" ]; then
        build_args="$build_args --build-arg BUILD_PROXY_HTTP=$BUILD_PROXY_HTTP"
        build_args="$build_args --build-arg BUILD_PROXY_HTTPS=$BUILD_PROXY_HTTPS"
        log_verbose "使用代理构建"
    fi

    # 设置构建标签
    local build_tag="searxng-mcp:latest"
    build_args="$build_args -t $build_tag"

    # 添加缓存参数（除非是 clean 部署）
    if [ "$CLEAN_DEPLOY" = true ]; then
        build_args="$build_args --no-cache"
        log_verbose "使用 --no-cache 构建"
    fi

    # 构建上下文
    local build_context="$TEMP_BUILD_DIR"

    log_info "正在构建镜像..."
    log_verbose "构建目录: $build_context"
    log_verbose "构建命令: docker build $build_args $build_context"

    # 执行构建
    if [ "$QUIET" = false ]; then
        eval "$build_cmd $build_args $build_context"
    else
        eval "$build_cmd $build_args $build_context" >/dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        log_success "镜像构建成功: $build_tag"
    else
        log_error "镜像构建失败"
        log_error "请查看构建日志以获取详细信息"
        exit 4
    fi
}

deploy_services() {
    log_step "启动服务"

    cd "$DEPLOY_DIR"

    # 检查 docker-compose.yml 是否存在
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml"
        exit 1
    fi

    log_verbose "使用 docker-compose 在: $DEPLOY_DIR"

    # 设置运行时代理环境变量
    local compose_env=""
    if [ -n "$PROXY_HTTP" ]; then
        compose_env="HTTP_PROXY=$PROXY_HTTP HTTPS_PROXY=$PROXY_HTTPS"
        log_verbose "使用运行时代理: $PROXY_HTTP"
    fi

    # 启动服务
    log_info "正在启动容器..."
    if [ -n "$compose_env" ]; then
        eval "$compose_env docker compose up -d"
    else
        docker compose up -d
    fi

    if [ $? -eq 0 ]; then
        log_success "容器已启动: searxng-mcp"
    else
        log_error "容器启动失败"
        exit 1
    fi
}

#############################################
# 健康检查和验证
#############################################

wait_for_services() {
    log_step "等待服务就绪"

    local max_wait=60
    local waited=0
    local interval=2

    log_info "等待 SearXNG 启动..."

    while [ $waited -lt $max_wait ]; do
        # 检查容器健康状态
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' searxng-mcp 2>/dev/null || echo "starting")

        if [ "$health_status" = "healthy" ]; then
            local elapsed=$((waited))
            log_success "SearXNG 已就绪（耗时 ${elapsed} 秒）"
            return 0
        fi

        # 检查容器是否在运行
        if ! docker ps | grep -q searxng-mcp; then
            log_error "容器未运行"
            return 1
        fi

        # 显示进度
        if [ "$QUIET" = false ]; then
            echo -n "."
        fi

        sleep $interval
        waited=$((waited + interval))
    done

    if [ "$QUIET" = false ]; then
        echo
    fi

    log_warn "服务未能在 ${max_wait} 秒内完全就绪，但将继续验证"
    return 0
}

test_searxng() {
    log_step "测试 SearXNG 服务"

    if curl -f -s http://localhost:8080 >/dev/null 2>&1; then
        log_success "SearXNG Web UI: http://localhost:8080"
        return 0
    else
        log_error "SearXNG 无法访问"
        return 1
    fi
}

test_mcp() {
    log_step "测试 MCP 服务"

    if curl -f -s http://localhost:3000/health >/dev/null 2>&1; then
        log_success "MCP 服务器: http://localhost:3000"
        return 0
    else
        log_warn "MCP HTTP 端点未响应（可能已禁用）"
        return 0
    fi
}

test_json_api() {
    log_step "测试 JSON API"

    local response=$(curl -s "http://localhost:8080/search?q=test&format=json" 2>/dev/null)

    if echo "$response" | grep -q '"results"'; then
        log_success "JSON API 测试通过"
        return 0
    else
        log_warn "JSON API 测试失败，但服务可能仍然可用"
        return 0
    fi
}

verify_deployment() {
    if [ "$SKIP_HEALTH_CHECK" = true ]; then
        log_info "跳过健康检查 (--skip-health-check)"
        return 0
    fi

    log_step "验证服务功能"

    local all_passed=true

    if ! test_searxng; then
        all_passed=false
    fi

    if ! test_mcp; then
        # MCP 测试失败不算致命错误
        :
    fi

    if ! test_json_api; then
        # JSON API 测试失败不算致命错误
        :
    fi

    if [ "$all_passed" = true ]; then
        log_success "所有服务验证通过"
        return 0
    else
        log_warn "部分服务验证失败，请检查日志"
        return 1
    fi
}

#############################################
# 信息展示
#############################################

show_deployment_info() {
    if [ "$QUIET" = false ]; then
        echo
        show_separator
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}                    ${GREEN}部署成功！${NC}                           ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "  • SearXNG Web UI:    ${GREEN}http://localhost:8080${NC}"
        echo -e "  • MCP 服务器:        ${GREEN}http://localhost:3000${NC}"
        echo
        echo -e "${CYAN}测试命令:${NC}"
        echo -e "  • 测试搜索: ${YELLOW}curl \"http://localhost:8080/search?q=test&format=json\"${NC}"
        echo -e "  • 测试 MCP:  ${YELLOW}curl http://localhost:3000/health${NC}"
        echo -e "  • 查看日志: ${YELLOW}docker logs -f searxng-mcp${NC}"
        echo
        echo -e "${CYAN}常用操作:${NC}"
        echo -e "  • 停止服务: ${YELLOW}cd $DEPLOY_DIR && docker-compose down${NC}"
        echo -e "  • 重启服务: ${YELLOW}cd $DEPLOY_DIR && docker-compose restart${NC}"
        echo -e "  • 查看日志: ${YELLOW}cd $DEPLOY_DIR && docker-compose logs -f${NC}"
        echo -e "  • 查看配置: 配置文件位于 ${YELLOW}$DEPLOY_DIR/searxng-config/${NC}"
        echo
        echo -e "${CYAN}日志文件:${NC}"
        echo -e "  • $LOG_FILE"
        echo
    fi

    log_verbose "部署文件已安装到: $DEPLOY_DIR/"
}

show_test_commands() {
    if [ "$QUIET" = false ]; then
        echo
        show_separator
        echo -e "${CYAN}快速测试命令:${NC}"
        echo
        echo -e "# 测试 SearXNG 搜索"
        echo -e "curl \"http://localhost:8080/search?q=test&format=json\" | jq"
        echo
        echo -e "# 测试 MCP 健康检查"
        echo -e "curl http://localhost:3000/health"
        echo
        echo -e "# 查看容器日志（实时）"
        echo -e "docker logs -f searxng-mcp"
        echo
        echo -e "# 检查容器状态"
        echo -e "docker ps | grep searxng-mcp"
        echo
    fi
}

show_logs() {
    if [ "$SHOW_LOGS" = true ]; then
        echo
        log_info "显示实时日志（按 Ctrl+C 退出）..."
        echo
        docker logs -f searxng-mcp
    fi
}

#############################################
# 参数解析
#############################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                CLEAN_DEPLOY=true
                shift
                ;;
            --no-proxy)
                NO_PROXY=true
                shift
                ;;
            --skip-health-check)
                SKIP_HEALTH_CHECK=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --logs)
                SHOW_LOGS=true
                shift
                ;;
            --config-only)
                CONFIG_ONLY=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

#############################################
# 主函数
#############################################

main() {
    # 初始化日志文件
    LOG_FILE="$DEPLOY_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$(dirname "$LOG_FILE")"

    # 解析参数
    parse_arguments "$@"

    # 显示欢迎信息
    show_welcome

    # 步骤 1: 下载代码（如果需要）
    show_separator
    log_step "步骤 1/9: 准备部署文件"
    download_and_build

    # 步骤 2: 检查运行环境
    show_separator
    log_step "步骤 2/9: 检查运行环境"
    check_docker
    check_ports
    check_system_resources

    # 步骤 3: 检测代理配置
    show_separator
    log_step "步骤 3/9: 检测代理配置"
    if detect_proxy; then
        convert_proxy_for_build
        verify_proxy_connection
        apply_proxy_settings
    fi

    # 步骤 4: 检查配置文件
    show_separator
    log_step "步骤 4/9: 检查配置文件"
    if [ "$CLEAN_DEPLOY" = true ]; then
        backup_configs
    fi
    setup_configs

    # 如果只是生成配置，到此结束
    if [ "$CONFIG_ONLY" = true ]; then
        log_info "仅生成配置文件，部署已完成"
        show_deployment_info
        return 0
    fi

    # 步骤 5: 构建 Docker 镜像
    show_separator
    log_step "步骤 5/9: 构建 Docker 镜像"
    build_image

    # 步骤 6: 拷贝运行时文件
    show_separator
    log_step "步骤 6/9: 拷贝运行时文件"
    copy_runtime_files

    # 步骤 7: 启动服务
    show_separator
    log_step "步骤 7/9: 启动服务"
    deploy_services

    # 步骤 8: 清理临时文件
    show_separator
    log_step "步骤 8/9: 清理临时文件"
    cleanup_temp_dir

    # 步骤 9: 验证部署
    show_separator
    log_step "步骤 9/9: 验证部署"
    wait_for_services
    verify_deployment

    # 显示部署信息
    show_separator
    show_deployment_info
    show_test_commands

    # 显示日志（如果需要）
    if [ "$SHOW_LOGS" = true ]; then
        show_logs
    fi

    return 0
}

# 运行主函数
main "$@"
