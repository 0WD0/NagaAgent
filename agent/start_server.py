#!/usr/bin/env python3
# agent/start_server.py
# 启动代理API服务器

import asyncio
import os
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from agent.api_server import start_server
from config import config as global_config

async def main():
    """主函数"""
    print("启动代理API服务器...")
    print("配置信息:")
    print(f"  - API URL: {global_config.api.base_url}")
    print(f"  - 服务器地址: {global_config.api_server.host}:{global_config.api_server.port}")
    print(f"  - 调试模式: {global_config.system.debug}")
    print(f"  - API密钥: {'已设置' if global_config.api.api_key else '未设置'}")
    print()
    
    try:
        await start_server()
    except KeyboardInterrupt:
        print("\n收到停止信号，正在关闭服务器...")
    except Exception as e:
        print(f"服务器启动失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main()) 
