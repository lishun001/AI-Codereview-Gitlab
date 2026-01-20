#!/bin/bash

# AI Code Review 服务启动脚本 (PM2 版本)
# 使用 PM2 进程管理器启动服务，提供自动重启、监控等功能

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

# 检查 PM2 是否安装
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        print_error "PM2 未安装"
        print_info "请先安装 PM2: npm install -g pm2"
        print_info "或使用 yarn: yarn global add pm2"
        exit 1
    fi
    
    PM2_VERSION=$(pm2 -v)
    print_success "检测到 PM2 版本: $PM2_VERSION"
}

# 检查 Python 环境
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 未安装，请先安装 Python 3.10+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    print_info "检测到 Python 版本: $PYTHON_VERSION"
}

# 安装 Python 依赖
install_dependencies() {
    print_info "检查 Python 依赖..."
    
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
    print_info "安装 Python 依赖包..."
    pip3 install -r requirements.txt -q
    print_success "依赖安装完成"
}

# 创建必要的目录
create_directories() {
    print_info "创建必要的目录..."
    mkdir -p data log
    print_success "目录创建完成"
}

# 使用 PM2 启动服务
start_with_pm2() {
    print_info "使用 PM2 启动服务..."
    
    # 检查是否已有运行的服务
    if pm2 list | grep -q "codereview-api\|codereview-ui"; then
        print_warning "检测到已运行的服务"
        read -p "是否重启服务? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "重启服务..."
            pm2 restart ecosystem.config.js
            print_success "服务重启成功"
        else
            print_info "取消操作"
            exit 0
        fi
    else
        # 启动服务
        print_info "启动 PM2 进程..."
        pm2 start ecosystem.config.js
        print_success "服务启动成功"
    fi
    
    # 保存 PM2 进程列表
    print_info "保存 PM2 进程列表..."
    pm2 save
    
    # 显示服务状态
    echo ""
    print_info "服务状态:"
    pm2 list
}

# 配置开机自启
setup_startup() {
    echo ""
    read -p "是否配置开机自启? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "配置开机自启..."
        pm2 startup
        print_info "请执行上面显示的命令（如果有）来完成配置"
        print_success "开机自启配置完成"
    fi
}

# 显示使用帮助
show_help() {
    echo "AI Code Review 服务启动脚本 (PM2 版本)"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  start            启动服务（默认）"
    echo "  stop             停止服务"
    echo "  restart          重启服务"
    echo "  status           查看服务状态"
    echo "  logs             查看日志"
    echo "  monit            实时监控"
    echo "  -h, --help       显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0               # 启动服务"
    echo "  $0 start         # 启动服务"
    echo "  $0 stop          # 停止服务"
    echo "  $0 restart       # 重启服务"
    echo "  $0 logs          # 查看日志"
    echo "  $0 monit         # 实时监控"
}

# 停止服务
stop_service() {
    print_info "停止 PM2 服务..."
    pm2 stop ecosystem.config.js
    print_success "服务已停止"
    pm2 list
}

# 重启服务
restart_service() {
    print_info "重启 PM2 服务..."
    pm2 restart ecosystem.config.js
    print_success "服务已重启"
    pm2 list
}

# 查看状态
show_status() {
    print_info "服务状态:"
    pm2 list
    echo ""
    print_info "详细信息:"
    pm2 show codereview-api
    pm2 show codereview-ui
}

# 查看日志
show_logs() {
    print_info "查看服务日志 (Ctrl+C 退出)..."
    pm2 logs
}

# 实时监控
show_monitor() {
    print_info "启动实时监控 (Ctrl+C 退出)..."
    pm2 monit
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "  AI Code Review 服务启动脚本 (PM2)"
    echo "=========================================="
    echo ""
    
    # 解析命令行参数
    ACTION="${1:-start}"
    
    case $ACTION in
        start)
            check_config
            check_pm2
            check_python
            install_dependencies
            create_directories
            start_with_pm2
            setup_startup
            
            echo ""
            echo "=========================================="
            print_success "服务启动完成！"
            echo "=========================================="
            echo ""
            print_info "API 服务地址: http://localhost:5001"
            print_info "Dashboard 地址: http://localhost:5002"
            echo ""
            print_info "常用命令:"
            print_info "  查看状态: pm2 list"
            print_info "  查看日志: pm2 logs"
            print_info "  实时监控: pm2 monit"
            print_info "  重启服务: pm2 restart all"
            print_info "  停止服务: pm2 stop all"
            print_info "  删除服务: pm2 delete all"
            echo ""
            ;;
        stop)
            check_pm2
            stop_service
            ;;
        restart)
            check_pm2
            restart_service
            ;;
        status)
            check_pm2
            show_status
            ;;
        logs)
            check_pm2
            show_logs
            ;;
        monit)
            check_pm2
            show_monitor
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "未知命令: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
