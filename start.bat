@echo off
chcp 65001 >nul
title NagaAgent 3.0

:: 切换到脚本所在目录
cd /d "%~dp0"

:: 检查是否使用 uv 管理环境
echo [INFO] 启动 NagaAgent 3.0...

:: 优先使用 uv 运行
where uv >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] 使用 uv 运行应用...
    uv run python main.py
) else (
    :: 回退到传统虚拟环境方式
    echo [INFO] 使用虚拟环境运行应用...
    if exist ".venv\Scripts\activate.bat" (
        call .venv\Scripts\activate.bat
        python main.py
    ) else (
        echo [ERROR] 未找到虚拟环境，请先运行 setup.ps1 进行环境配置
        echo [ERROR] 或直接使用: python main.py
        pause
        exit /b 1
    )
)

pause 