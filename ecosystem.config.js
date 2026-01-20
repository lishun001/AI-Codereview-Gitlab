/**
 * PM2 进程管理配置文件
 * AI Code Review 服务
 * 
 * 使用方法:
 *   pm2 start ecosystem.config.js
 *   pm2 stop all
 *   pm2 restart all
 *   pm2 logs
 *   pm2 monit
 */

module.exports = {
  apps: [
    {
      name: 'codereview-api',
      script: 'api.py',
      interpreter: 'python3',
      cwd: './',
      
      // 实例配置
      instances: 1,
      exec_mode: 'fork',
      
      // 自动重启配置
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      
      // 内存限制
      max_memory_restart: '1G',
      
      // 日志配置
      error_file: './log/api-error.log',
      out_file: './log/api-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      
      // 环境变量
      env: {
        NODE_ENV: 'production',
        PORT: 5001
      },
      
      // 开发环境变量
      env_development: {
        NODE_ENV: 'development',
        PORT: 5001
      }
    },
    {
      name: 'codereview-ui',
      script: 'streamlit',
      args: 'run ui.py --server.port=5002 --server.address=0.0.0.0 --server.headless=true',
      interpreter: 'none',
      cwd: './',
      
      // 实例配置
      instances: 1,
      exec_mode: 'fork',
      
      // 自动重启配置
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      
      // 内存限制
      max_memory_restart: '1G',
      
      // 日志配置
      error_file: './log/ui-error.log',
      out_file: './log/ui-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      
      // 环境变量
      env: {
        NODE_ENV: 'production',
        PORT: 5002
      },
      
      // 开发环境变量
      env_development: {
        NODE_ENV: 'development',
        PORT: 5002
      }
    }
  ],
  
  // 部署配置（可选）
  deploy: {
    production: {
      user: 'deploy',
      host: 'your-server.com',
      ref: 'origin/main',
      repo: 'git@github.com:your-repo/AI-Codereview-Gitlab.git',
      path: '/var/www/codereview',
      'post-deploy': 'pip3 install -r requirements.txt && pm2 reload ecosystem.config.js --env production'
    }
  }
};
