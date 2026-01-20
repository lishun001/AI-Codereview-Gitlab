# AI Code Review 启动脚本使用指南

本项目提供了多种启动方式，您可以根据实际需求选择合适的方案。

## 📋 启动方式对比

| 方式 | 脚本 | 优点 | 适用场景 |
|------|------|------|----------|
| **Docker** | `./start.sh` | 环境隔离、一键部署 | 生产环境、快速部署 |
| **Python + nohup** | `./start.sh -p` | 简单轻量、系统自带 | 开发测试、临时运行 |
| **PM2** | `./start-pm2.sh` | 自动重启、监控管理 | 生产环境、长期运行 |
| **Supervisor** | 手动配置 | 系统级管理、稳定可靠 | 生产环境、企业部署 |

---

## 🚀 方式一：Docker 启动（推荐）

### 优点
- ✅ 环境隔离，不污染系统
- ✅ 一键启动，无需配置环境
- ✅ 跨平台兼容性好

### 使用方法

```bash
# 1. 启动服务（默认使用 Docker）
./start.sh

# 或明确指定 Docker 方式
./start.sh -d

# 2. 查看日志
docker-compose logs -f

# 3. 停止服务
./stop.sh -d
# 或
docker-compose down
```

### 访问地址
- API 服务: http://localhost:5001
- Dashboard: http://localhost:5002

---

## 🐍 方式二：Python + nohup 启动

### 优点
- ✅ 无需安装额外工具
- ✅ 适合快速测试
- ✅ 系统资源占用少

### 缺点
- ❌ 无自动重启
- ❌ 无进程监控
- ❌ 手动管理进程

### 使用方法

```bash
# 1. 启动服务
./start.sh -p

# 2. 查看日志
tail -f log/api.log
tail -f log/ui.log

# 3. 停止服务
./stop.sh -p
```

### 手动启动（不使用脚本）

```bash
# 创建虚拟环境
python3 -m venv .venv
source .venv/bin/activate

# 安装依赖
pip3 install -r requirements.txt

# 创建必要目录
mkdir -p data log

# 启动 API 服务
nohup python3 api.py > log/api.log 2>&1 &
echo $! > .api.pid

# 启动 Dashboard 服务
nohup streamlit run ui.py --server.port=5002 --server.address=0.0.0.0 > log/ui.log 2>&1 &
echo $! > .ui.pid

# 查看进程
ps aux | grep "python.*api.py"
ps aux | grep "streamlit.*ui.py"

# 停止服务
kill $(cat .api.pid)
kill $(cat .ui.pid)
```

---

## 🔄 方式三：PM2 启动（推荐生产环境）

### 优点
- ✅ 自动重启（崩溃后自动恢复）
- ✅ 进程监控（CPU、内存实时监控）
- ✅ 日志管理（自动分割、轮转）
- ✅ 负载均衡（支持集群模式）
- ✅ 开机自启
- ✅ 零停机重载

### 前置要求

```bash
# 安装 Node.js (如果未安装)
# macOS
brew install node

# Ubuntu/Debian
sudo apt install nodejs npm

# 安装 PM2
npm install -g pm2
```

### 使用方法

```bash
# 1. 启动服务
./start-pm2.sh start

# 2. 查看服务状态
./start-pm2.sh status
# 或
pm2 list

# 3. 查看日志
./start-pm2.sh logs
# 或
pm2 logs

# 4. 实时监控
./start-pm2.sh monit
# 或
pm2 monit

# 5. 重启服务
./start-pm2.sh restart
# 或
pm2 restart all

# 6. 停止服务
./start-pm2.sh stop
# 或
pm2 stop all

# 7. 删除服务
pm2 delete all
```

### PM2 常用命令

```bash
# 查看所有进程
pm2 list

# 查看详细信息
pm2 show codereview-api
pm2 show codereview-ui

# 查看日志
pm2 logs                    # 所有日志
pm2 logs codereview-api     # API 日志
pm2 logs codereview-ui      # UI 日志
pm2 logs --lines 100        # 最近 100 行

# 实时监控
pm2 monit

# 重启服务
pm2 restart codereview-api
pm2 restart all

# 停止服务
pm2 stop codereview-api
pm2 stop all

# 删除服务
pm2 delete codereview-api
pm2 delete all

# 清空日志
pm2 flush

# 保存进程列表
pm2 save

# 配置开机自启
pm2 startup
pm2 save
```

### PM2 配置文件

项目已包含 [`ecosystem.config.js`](ecosystem.config.js) 配置文件，可以自定义：

```javascript
module.exports = {
  apps: [
    {
      name: 'codereview-api',
      script: 'api.py',
      interpreter: 'python3',
      autorestart: true,
      max_memory_restart: '1G',
      error_file: './log/api-error.log',
      out_file: './log/api-out.log'
    },
    {
      name: 'codereview-ui',
      script: 'ui.py',
      interpreter: 'python3',
      autorestart: true,
      max_memory_restart: '1G',
      error_file: './log/ui-error.log',
      out_file: './log/ui-out.log'
    }
  ]
};
```

---

## 🔧 方式四：Supervisor 启动

项目已包含 Supervisor 配置文件 [`conf/supervisord.conf`](conf/supervisord.conf)。

### 安装 Supervisor

```bash
# macOS
brew install supervisor

# Ubuntu/Debian
sudo apt install supervisor

# 或使用 pip
pip3 install supervisor
```

### 使用方法

```bash
# 1. 启动 Supervisor
supervisord -c conf/supervisord.conf

# 2. 查看状态
supervisorctl -c conf/supervisord.conf status

# 3. 启动服务
supervisorctl -c conf/supervisord.conf start all

# 4. 停止服务
supervisorctl -c conf/supervisord.conf stop all

# 5. 重启服务
supervisorctl -c conf/supervisord.conf restart all

# 6. 查看日志
tail -f log/api.log
tail -f log/ui.log
```

---

## 📊 启动方式选择建议

### 开发测试环境
```bash
# 快速测试 - 使用 Python + nohup
./start.sh -p

# 或使用 Docker（环境隔离）
./start.sh
```

### 生产环境
```bash
# 推荐方案 1: PM2（功能最全）
./start-pm2.sh start

# 推荐方案 2: Docker（容器化）
./start.sh

# 推荐方案 3: Supervisor（系统级）
supervisord -c conf/supervisord.conf
```

---

## 🔍 故障排查

### 1. 端口被占用

```bash
# 查看端口占用
lsof -i :5001
lsof -i :5002

# 杀死占用进程
kill -9 <PID>
```

### 2. 服务无法启动

```bash
# 查看日志
tail -f log/api.log
tail -f log/ui.log

# 检查配置文件
cat conf/.env

# 检查 Python 环境
python3 --version
pip3 list
```

### 3. PM2 服务异常

```bash
# 查看详细错误
pm2 logs --err

# 重置 PM2
pm2 kill
pm2 start ecosystem.config.js

# 清空日志
pm2 flush
```

### 4. Docker 服务异常

```bash
# 查看容器日志
docker-compose logs -f

# 重启容器
docker-compose restart

# 重建容器
docker-compose down
docker-compose up -d --build
```

---

## 📝 配置文件说明

### 环境配置文件: `conf/.env`

首次启动时，脚本会自动从 `conf/.env.dist` 复制配置文件。

必须配置的参数：
- `LLM_PROVIDER`: LLM 提供商（openai/deepseek/qwen 等）
- `API_KEY`: LLM API 密钥
- `GITLAB_URL`: GitLab 服务器地址
- `GITLAB_TOKEN`: GitLab 访问令牌

### PM2 配置文件: `ecosystem.config.js`

可自定义：
- 进程名称
- 内存限制
- 日志路径
- 环境变量
- 集群配置

### Supervisor 配置文件: `conf/supervisord.conf`

可自定义：
- 进程管理
- 日志配置
- 自动重启策略

---

## 🎯 快速开始

### 第一次使用

```bash
# 1. 克隆项目
git clone <repository-url>
cd AI-Codereview-Gitlab

# 2. 配置环境变量
cp conf/.env.dist conf/.env
vim conf/.env  # 编辑配置

# 3. 选择启动方式

# 方式 A: Docker（推荐新手）
./start.sh

# 方式 B: PM2（推荐生产）
npm install -g pm2
./start-pm2.sh start

# 方式 C: Python + nohup（快速测试）
./start.sh -p
```

### 日常使用

```bash
# 启动服务
./start-pm2.sh start

# 查看状态
pm2 list

# 查看日志
pm2 logs

# 停止服务
pm2 stop all
```

---

## 📚 相关文档

- [项目 README](README.md)
- [脚本说明](SCRIPTS_README.md)
- [PM2 官方文档](https://pm2.keymetrics.io/)
- [Docker 官方文档](https://docs.docker.com/)
- [Supervisor 官方文档](http://supervisord.org/)

---

## 💡 提示

1. **生产环境建议使用 PM2 或 Supervisor**，提供自动重启和监控功能
2. **开发测试可以使用 nohup**，简单快速
3. **Docker 适合快速部署和环境隔离**
4. **定期查看日志文件**，及时发现问题
5. **配置开机自启**，确保服务高可用

---

## ❓ 常见问题

**Q: 如何选择启动方式？**
A: 生产环境推荐 PM2 或 Docker，开发测试推荐 nohup。

**Q: PM2 和 nohup 有什么区别？**
A: PM2 提供自动重启、监控、日志管理等功能，nohup 只是简单的后台运行。

**Q: 如何查看服务是否正常运行？**
A: 使用 `pm2 list` 或 `ps aux | grep python` 查看进程状态。

**Q: 如何配置开机自启？**
A: 使用 PM2: `pm2 startup && pm2 save`

**Q: 日志文件在哪里？**
A: 默认在 `log/` 目录下，包括 `api.log`、`ui.log` 等。
