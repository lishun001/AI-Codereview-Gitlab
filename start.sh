#!/bin/bash

# AI Code Review 服务启动脚本
# 支持 Docker 和本地 Python 两种启动方式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查配置文件
check_config() {
    if [ ! -f "conf/.env" ]; then
        print_warning "配置文件 conf/.env 不存在"
        if [ -f "conf/.env.dist" ]; then
            print_info "正在从 conf/.env.dist 创建配置文件..."
            cp conf/.env.dist conf/.env
            print_warning "请编辑 conf/.env 文件，配置必要的参数（如 LLM_PROVIDER, API_KEY 等）"
            print_info "配置完成后，请重新运行此脚本"
            exit 1
        else
            print_error "找不到配置模板文件 conf/.env.dist"
            exit 1
        fi
    fi
    print_success "配置文件检查通过"
}

# Docker 方式启动
start_with_docker() {
    print_info "使用 Docker 方式启动服务..."
    
    # 检查 Docker 是否安装
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 检查 docker-compose 是否安装
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "docker-compose 未安装，请先安装 docker-compose"
        exit 1
    fi
    
    # 创建必要的目录
    mkdir -p data log
    
    print_info "启动 Docker 容器..."
    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi
    
    print_success "Docker 容器启动成功！"
    print_info "API 服务地址: http://localhost:5001"
    print_info "Dashboard 地址: http://localhost:5002"
    print_info ""
    print_info "查看日志: docker-compose logs -f"
    print_info "停止服务: docker-compose down"
}

# Python 方式启动
start_with_python() {
    print_info "使用本地 Python 方式启动服务..."
    
    # 检查 Python 版本
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 未安装，请先安装 Python 3.10+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    print_info "检测到 Python 版本: $PYTHON_VERSION"
    
    # 检查虚拟环境
    if [ ! -d ".venv" ]; then
        print_warning "虚拟环境不存在，正在创建..."
        python3 -m venv .venv
        print_success "虚拟环境创建成功"
    fi
    
    # 激活虚拟环境
    print_info "激活虚拟环境..."
    source .venv/bin/activate
    
    # 安装依赖
    print_info "检查并安装依赖..."
    pip3 install -r requirements.txt -q
    
    # 创建必要的目录
    mkdir -p data log
    
    # 启动服务
    print_info "启动 API 服务..."
    print_info "API 服务将在后台运行，日志输出到 log/api.log"
    nohup python3 api.py > log/api.log 2>&1 &
    API_PID=$!
    echo $API_PID > .api.pid
    print_success "API 服务已启动 (PID: $API_PID)"
    
    # 等待 API 服务启动
    sleep 3
    
    print_info "启动 Dashboard 服务..."
    print_info "Dashboard 服务将在后台运行，日志输出到 log/ui.log"
    nohup streamlit run ui.py --server.port=5002 --server.address=0.0.0.0 > log/ui.log 2>&1 &
    UI_PID=$!
    echo $UI_PID > .ui.pid
    print_success "Dashboard 服务已启动 (PID: $UI_PID)"
    
    print_success "所有服务启动成功！"
    print_info "API 服务地址: http://localhost:5001"
    print_info "Dashboard 地址: http://localhost:5002"
    print_info ""
    print_info "查看 API 日志: tail -f log/api.log"
    print_info "查看 Dashboard 日志: tail -f log/ui.log"
    print_info "停止服务: ./stop.sh"
}

# 显示使用帮助
show_help() {
    echo "AI Code Review 服务启动脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --docker     使用 Docker 方式启动（默认）"
    echo "  -p, --python     使用本地 Python 方式启动"
    echo "  -h, --help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 使用 Docker 方式启动"
    echo "  $0 -d           # 使用 Docker 方式启动"
    echo "  $0 -p           # 使用本地 Python 方式启动"
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "  AI Code Review 服务启动脚本"
    echo "=========================================="
    echo ""
    
    # 检查配置文件
    check_config
    
    # 解析命令行参数
    MODE="docker"  # 默认使用 Docker 方式
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--docker)
                MODE="docker"
                shift
                ;;
            -p|--python)
                MODE="python"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 根据模式启动服务
    if [ "$MODE" = "docker" ]; then
        start_with_docker
    else
        start_with_python
    fi
    
    echo ""
    echo "=========================================="
    print_success "服务启动完成！"
    echo "=========================================="
    echo ""
}

# 执行主函数
main "$@"
