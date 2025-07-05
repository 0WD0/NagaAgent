#!/bin/bash
# NagaAgent 3.0 Linux 启动脚本

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 颜色输出函数
print_info() {
    echo -e "\033[96m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[91m[ERROR]\033[0m $1"
}

print_info "启动 NagaAgent 3.0..."

# 优先使用 uv 运行
if command -v uv &> /dev/null; then
    print_info "使用 uv 运行应用..."
    export PYTHONPATH="$(pwd):$PYTHONPATH"
    uv run python main.py
else
    # 回退到传统虚拟环境方式
    print_info "使用虚拟环境运行应用..."
    if [[ -f ".venv/bin/activate" ]]; then
        source .venv/bin/activate
        export PYTHONPATH="$(pwd):$PYTHONPATH"
        python main.py
    else
        print_error "未找到虚拟环境，请先运行 ./setup_linux.sh 进行环境配置"
        print_error "或直接使用: python3 main.py"
        exit 1
    fi
fi 