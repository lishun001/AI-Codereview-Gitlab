# 服务管理脚本使用说明

本项目提供了三个便捷的 Shell 脚本来管理 AI Code Review 服务。

## 📋 脚本列表

- [`start.sh`](start.sh) - 启动服务脚本
- [`stop.sh`](stop.sh) - 停止服务脚本
- [`status.sh`](status.sh) - 状态检查脚本

## 🚀 快速开始

### 1. 启动服务

#### 使用 Docker 方式启动（推荐）

```bash
./start.sh
# 或
./start.sh -d
# 或
./start.sh --docker
```

#### 使用本地 Python 方式启动

```bash
./start.sh -p
# 或
./start.sh --python
```

### 2. 检查服务状态

```bash
./status.sh
```

该脚本会检查：
- Docker 容器运行状态
- Python 进程运行状态
- 端口占用情况（5001, 5002）
- 服务可访问性测试

### 3. 停止服务

#### 停止所有服务

```bash
./stop.sh
# 或
./stop.sh -a
# 或
./stop.sh --all
```

#### 仅停止 Docker 服务

```bash
./stop.sh -d
# 或
./stop.sh --docker
```

#### 仅停止 Python 服务

```bash
./stop.sh -p
# 或
./stop.sh --python
```

## 📝 详细说明

### start.sh - 启动服务脚本

**功能特性：**

- ✅ 自动检查配置文件（`conf/.env`）
- ✅ 如果配置文件不存在，自动从 `conf/.env.dist` 创建
- ✅ 支持 Docker 和本地 Python 两种启动方式
- ✅ Docker 模式：自动检查 Docker 和 docker-compose 安装
- ✅ Python 模式：
  - 检查 Python 版本（需要 3.10+）
  - 自动创建虚拟环境（如果不存在）
  - 自动安装依赖
  - 后台运行服务并记录 PID
- ✅ 创建必要的目录（data, log）
- ✅ 彩色输出，清晰易读

**使用示例：**

```bash
# 查看帮助
./start.sh -h

# Docker 方式启动
./start.sh

# Python 方式启动
./start.sh -p
```

**启动后的服务地址：**

- API 服务：http://localhost:5001
- Dashboard：http://localhost:5002

### stop.sh - 停止服务脚本

**功能特性：**

- ✅ 支持停止 Docker 和 Python 服务
- ✅ 通过 PID 文件精确停止进程
- ✅ 自动清理残留进程
- ✅ 清理 PID 文件
- ✅ 彩色输出，清晰易读

**使用示例：**

```bash
# 查看帮助
./stop.sh -h

# 停止所有服务
./stop.sh

# 仅停止 Docker 服务
./stop.sh -d

# 仅停止 Python 服务
./stop.sh -p
```

### status.sh - 状态检查脚本

**功能特性：**

- ✅ 检查 Docker 容器状态
- ✅ 检查 Python 进程状态
- ✅ 检查端口占用情况（5001, 5002）
- ✅ 测试服务可访问性
- ✅ 彩色输出，状态一目了然

**使用示例：**

```bash
./status.sh
```

**输出示例：**

```
==========================================
  AI Code Review 服务状态检查
==========================================

[INFO] 检查 Docker 服务状态...
[✓] Docker 服务正在运行

[INFO] 检查 Python 服务状态...
[✓] API 服务正在运行 (PID: 12345)
[✓] Dashboard 服务正在运行 (PID: 12346)

[INFO] 检查端口占用情况...
[✓] 端口 5001 (API) 正在使用
[✓] 端口 5002 (Dashboard) 正在使用

[INFO] 检查服务可访问性...
[✓] API 服务可访问: http://localhost:5001
[✓] Dashboard 服务可访问: http://localhost:5002

==========================================
[INFO] 状态检查完成
==========================================
```

## 🔧 首次使用配置

### 1. 配置环境变量

首次运行 `start.sh` 时，如果 `conf/.env` 不存在，脚本会自动从 `conf/.env.dist` 创建配置文件。

**必须配置的参数：**

```bash
# 大模型供应商（支持 deepseek, openai, zhipuai, qwen, ollama, anthropic）
LLM_PROVIDER=deepseek

# API Key（根据选择的供应商配置对应的 Key）
DEEPSEEK_API_KEY=your_api_key_here

# GitLab Access Token
GITLAB_ACCESS_TOKEN=your_gitlab_token_here

# 支持的文件类型
SUPPORTED_EXTENSIONS=.java,.py,.php,.yml,.vue,.go,.c,.cpp,.h,.js,.css,.md,.sql
```

### 2. 配置 GitLab Webhook

在 GitLab 项目设置中配置 Webhook：

- **URL**: `http://your-server-ip:5001/review/webhook`
- **Trigger Events**: 勾选 `Push Events` 和 `Merge Request Events`
- **Secret Token**: 使用上面配置的 Access Token（可选）

## 📊 日志查看

### Docker 方式

```bash
# 查看所有日志
docker-compose logs -f

# 仅查看 API 日志
docker-compose logs -f app
```

### Python 方式

```bash
# 查看 API 日志
tail -f log/api.log

# 查看 Dashboard 日志
tail -f log/ui.log

# 查看应用日志
tail -f log/app.log
```

## ⚠️ 注意事项

1. **权限问题**：确保脚本有执行权限
   ```bash
   chmod +x start.sh stop.sh status.sh
   ```

2. **端口占用**：确保 5001 和 5002 端口未被占用

3. **Python 版本**：本地 Python 方式需要 Python 3.10+

4. **Docker 版本**：Docker 方式需要安装 Docker 和 docker-compose

5. **网络访问**：确保 GitLab 能够访问部署的服务地址

## 🐛 故障排查

### 服务无法启动

1. 检查配置文件是否正确：`cat conf/.env`
2. 检查端口是否被占用：`./status.sh`
3. 查看日志文件：`tail -f log/api.log`

### Docker 容器无法启动

```bash
# 查看容器日志
docker-compose logs

# 重新构建镜像
docker-compose build --no-cache
docker-compose up -d
```

### Python 服务无法启动

```bash
# 检查 Python 版本
python3 --version

# 重新安装依赖
source .venv/bin/activate
pip install -r requirements.txt

# 手动启动查看错误
python3 api.py
```

## 📚 更多信息

详细的项目文档请参考：[README.md](README.md)

常见问题请参考：[doc/faq.md](doc/faq.md)
