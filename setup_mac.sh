#!/bin/bash
# NagaAgent 3.0 macOS 环境配置脚本
# 使用 uv 作为主要包管理器，提供更快的依赖安装体验

set -e

# 配置参数
PYTHON_MIN_VERSION="3.8"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 颜色输出函数
print_step() {
    echo -e "\033[94m🚀 $1\033[0m"
}

print_success() {
    echo -e "\033[92m✅ $1\033[0m"
}

print_warning() {
    echo -e "\033[93m⚠️ $1\033[0m"
}

print_error() {
    echo -e "\033[91m❌ $1\033[0m"
}

print_info() {
    echo -e "\033[96m📋 $1\033[0m"
}

# 切换到项目目录
cd "$PROJECT_ROOT"

print_step "NagaAgent 3.0 macOS 环境配置开始..."

# 检查 Python 版本
print_step "检查 Python 版本..."
if ! command -v python3 &> /dev/null; then
    print_error "未找到 python3 命令，请先安装 Python $PYTHON_MIN_VERSION 或更高版本"
    print_info "推荐使用 Homebrew 安装: brew install python@3.11"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | grep -o '[0-9]\+\.[0-9]\+')
if [[ "$(printf '%s\n' "$PYTHON_MIN_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$PYTHON_MIN_VERSION" ]]; then
    print_error "需要 Python $PYTHON_MIN_VERSION 或更高版本，当前版本: $PYTHON_VERSION"
    exit 1
fi

print_success "Python 版本检查通过: $PYTHON_VERSION"

# 检查系统架构
if [[ $(uname -m) == "arm64" ]]; then
    print_info "检测到 Apple Silicon Mac"
    export SYSTEM_VERSION_COMPAT=1
else
    print_info "检测到 Intel Mac"
fi

# 检查并安装 uv
print_step "检查 uv 包管理器..."
if ! command -v uv &> /dev/null; then
    print_step "正在安装 uv..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        # 刷新环境变量
        export PATH="$HOME/.local/bin:$PATH"
        
        # 验证安装
        if command -v uv &> /dev/null; then
            print_success "uv 安装成功"
            USE_UV=true
        else
            print_warning "uv 自动安装失败，将使用 pip 方式"
            USE_UV=false
        fi
    else
        print_warning "uv 安装失败，将使用 pip 方式"
        USE_UV=false
    fi
else
    print_success "uv 已安装"
    USE_UV=true
fi

# 检查系统依赖
print_step "检查系统依赖..."
if ! command -v portaudio &> /dev/null && ! brew list portaudio &> /dev/null 2>&1; then
    print_warning "未检测到 PortAudio，PyAudio 可能安装失败"
    print_info "如需语音功能，请运行: brew install portaudio"
fi

# 使用 uv 或 pip 安装依赖
if [[ "$USE_UV" == true ]]; then
    print_step "使用 uv 安装依赖（推荐方式）..."
    if uv sync; then
        print_success "uv 依赖安装完成"
    else
        print_warning "uv 安装失败，回退到 pip 方式"
        USE_UV=false
    fi
fi

if [[ "$USE_UV" != true ]]; then
    print_step "使用 pip 安装依赖..."
    
    # 创建虚拟环境
    if [[ ! -d ".venv" ]]; then
        print_step "创建虚拟环境..."
        python3 -m venv .venv
    fi
    
    # 激活虚拟环境
    print_step "激活虚拟环境..."
    source .venv/bin/activate
    
    # 升级 pip
    print_step "升级 pip..."
    python -m pip install --upgrade pip
    
    # 安装依赖
    print_step "安装项目依赖..."
    pip install -e .
    
    print_success "pip 依赖安装完成"
fi

# 特殊处理 PyAudio（如果需要）
if [[ "$USE_UV" == true ]]; then
    print_step "检查 PyAudio 依赖..."
    if ! uv run python -c "import pyaudio" &> /dev/null; then
        print_warning "PyAudio 可能需要系统依赖，尝试安装 PortAudio..."
        if command -v brew &> /dev/null; then
            brew install portaudio
            uv sync
        fi
    fi
fi

# 安装 playwright 浏览器驱动
print_step "安装 playwright 浏览器驱动..."
if [[ "$USE_UV" == true ]]; then
    if uv run python -m playwright install chromium; then
        print_success "playwright 驱动安装完成"
    else
        print_warning "playwright 驱动安装失败，请手动运行: uv run python -m playwright install chromium"
    fi
else
    if python -m playwright install chromium; then
        print_success "playwright 驱动安装完成"
    else
        print_warning "playwright 驱动安装失败，请手动运行: python -m playwright install chromium"
    fi
fi

# 环境检查
print_step "执行环境检查..."
if [[ "$USE_UV" == true ]]; then
    if uv run python check_env.py; then
        print_success "环境检查通过"
    else
        print_warning "环境检查失败，请检查依赖安装是否完整"
    fi
else
    if python check_env.py; then
        print_success "环境检查通过"
    else
        print_warning "环境检查失败，请检查依赖安装是否完整"
    fi
fi

print_success "✨ NagaAgent 3.0 macOS 环境配置完成！"
echo ""
print_info "🎯 启动应用："
echo "   ./start_mac.sh"
echo ""
print_info "📚 可选操作："
echo "   python -m playwright install firefox   # 安装 Firefox 驱动"
echo "   python -m playwright install webkit    # 安装 WebKit 驱动"
echo ""
print_info "🔧 故障排除："
echo "   如遇到依赖问题，请运行: uv sync --reload"
echo "   如遇到权限问题，请运行: chmod +x setup_mac.sh start_mac.sh" 