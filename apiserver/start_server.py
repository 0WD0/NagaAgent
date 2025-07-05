#!/usr/bin/env python3
"""
NagaAgent API服务器启动脚本
"""

import asyncio
import sys
import os
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from apiserver.api_server import app
from config import config
import uvicorn

async def main():
    """主函数"""
    # 从统一配置系统获取配置
    host = config.api_server.host
    port = config.api_server.port
    reload = config.system.debug
    
    print("🚀 启动NagaAgent API服务器...")
    print(f"📍 地址: http://{host}:{port}")
    print(f"📚 文档: http://{host}:{port}/docs")
    print(f"🔄 自动重载: {'开启' if reload else '关闭'}")
    
    # 启动服务器
    uvicorn.run(
        "apiserver.api_server:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info"
    )

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 收到停止信号，正在关闭服务器...")
    except Exception as e:
        print(f"❌ 启动失败: {e}")
        sys.exit(1) 
