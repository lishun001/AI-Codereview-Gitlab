#!/bin/bash

# AI Code Review 服务停止脚本

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

# 停止 Docker 服务
stop_docker() {
    print_info "停止 Docker 容器..."
    
    if docker compose version &> /dev/null; then
        docker compose down
    elif command -v docker-compose &> /dev/null; then
        docker-compose down
    else
        print_warning "未找到 docker-compose 命令"
        return 1
    fi
    
    print_success "Docker 容器已停止"
}

# 停止 Python 服务
stop_python() {
    print_info "停止 Python 服务..."
    
    # 停止 API 服务
    if [ -f ".api.pid" ]; then
        API_PID=$(cat .api.pid)
        if ps -p $API_PID > /dev/null 2>&1; then
            print_info "停止 API 服务 (PID: $API_PID)..."
            kill $API_PID
            print_success "API 服务已停止"
        else
            print_warning "API 服务进程不存在 (PID: $API_PID)"
        fi
        rm -f .api.pid
    else
        print_warning "未找到 API 服务 PID 文件"
    fi
    
    # 停止 Dashboard 服务
    if [ -f ".ui.pid" ]; then
        UI_PID=$(cat .ui.pid)
        if ps -p $UI_PID > /dev/null 2>&1; then
            print_info "停止 Dashboard 服务 (PID: $UI_PID)..."
            kill $UI_PID
            print_success "Dashboard 服务已停止"
        else
            print_warning "Dashboard 服务进程不存在 (PID: $UI_PID)"
        fi
        rm -f .ui.pid
    else
        print_warning "未找到 Dashboard 服务 PID 文件"
    fi
    
    # 额外检查并清理可能残留的进程
    print_info "检查残留进程..."
    pkill -f "python.*api.py" 2>/dev/null && print_info "清理了残留的 API 进程" || true
    pkill -f "streamlit.*ui.py" 2>/dev/null && print_info "清理了残留的 Dashboard 进程" || true
}

# 显示使用帮助
show_help() {
    echo "AI Code Review 服务停止脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --docker     停止 Docker 服务"
    echo "  -p, --python     停止本地 Python 服务"
    echo "  -a, --all        停止所有服务（Docker 和 Python）"
    echo "  -h, --help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 停止所有服务"
    echo "  $0 -d           # 停止 Docker 服务"
    echo "  $0 -p           # 停止本地 Python 服务"
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "  AI Code Review 服务停止脚本"
    echo "=========================================="
    echo ""
    
    # 解析命令行参数
    MODE="all"  # 默认停止所有服务
    
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
            -a|--all)
                MODE="all"
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
    
    # 根据模式停止服务
    if [ "$MODE" = "docker" ]; then
        stop_docker
    elif [ "$MODE" = "python" ]; then
        stop_python
    else
        # 停止所有服务
        stop_docker 2>/dev/null || true
        stop_python 2>/dev/null || true
    fi
    
    echo ""
    echo "=========================================="
    print_success "服务停止完成！"
    echo "=========================================="
    echo ""
}

# 执行主函数
main "$@"
