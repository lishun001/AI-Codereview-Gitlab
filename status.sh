#!/bin/bash

# AI Code Review 服务状态检查脚本

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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo ""
echo "=========================================="
echo "  AI Code Review 服务状态检查"
echo "=========================================="
echo ""

# 检查 Docker 服务
print_info "检查 Docker 服务状态..."
if command -v docker &> /dev/null; then
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "ai-codereview"; then
        print_success "Docker 服务正在运行"
        echo ""
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "ai-codereview" || docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -1
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "ai-codereview"
        echo ""
    else
        print_warning "Docker 服务未运行"
    fi
else
    print_warning "Docker 未安装"
fi

echo ""

# 检查 Python 服务
print_info "检查 Python 服务状态..."

# 检查 API 服务
if [ -f ".api.pid" ]; then
    API_PID=$(cat .api.pid)
    if ps -p $API_PID > /dev/null 2>&1; then
        print_success "API 服务正在运行 (PID: $API_PID)"
    else
        print_error "API 服务进程不存在 (PID: $API_PID)"
    fi
else
    if pgrep -f "python.*api.py" > /dev/null 2>&1; then
        API_PID=$(pgrep -f "python.*api.py")
        print_warning "API 服务正在运行但未找到 PID 文件 (PID: $API_PID)"
    else
        print_warning "API 服务未运行"
    fi
fi

# 检查 Dashboard 服务
if [ -f ".ui.pid" ]; then
    UI_PID=$(cat .ui.pid)
    if ps -p $UI_PID > /dev/null 2>&1; then
        print_success "Dashboard 服务正在运行 (PID: $UI_PID)"
    else
        print_error "Dashboard 服务进程不存在 (PID: $UI_PID)"
    fi
else
    if pgrep -f "streamlit.*ui.py" > /dev/null 2>&1; then
        UI_PID=$(pgrep -f "streamlit.*ui.py")
        print_warning "Dashboard 服务正在运行但未找到 PID 文件 (PID: $UI_PID)"
    else
        print_warning "Dashboard 服务未运行"
    fi
fi

echo ""

# 检查端口占用
print_info "检查端口占用情况..."

if lsof -i :5001 > /dev/null 2>&1; then
    print_success "端口 5001 (API) 正在使用"
    lsof -i :5001 | grep LISTEN
else
    print_warning "端口 5001 (API) 未被占用"
fi

if lsof -i :5002 > /dev/null 2>&1; then
    print_success "端口 5002 (Dashboard) 正在使用"
    lsof -i :5002 | grep LISTEN
else
    print_warning "端口 5002 (Dashboard) 未被占用"
fi

echo ""

# 检查服务可访问性
print_info "检查服务可访问性..."

if curl -s http://localhost:5001 > /dev/null 2>&1; then
    print_success "API 服务可访问: http://localhost:5001"
else
    print_error "API 服务不可访问: http://localhost:5001"
fi

if curl -s http://localhost:5002 > /dev/null 2>&1; then
    print_success "Dashboard 服务可访问: http://localhost:5002"
else
    print_error "Dashboard 服务不可访问: http://localhost:5002"
fi

echo ""
echo "=========================================="
print_info "状态检查完成"
echo "=========================================="
echo ""
