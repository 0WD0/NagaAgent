#!/bin/bash
# NagaAgent 3.0 Linux 环境配置脚本
# 支持 Ubuntu/Debian、CentOS/RHEL、Fedora、Arch Linux 等主流发行版

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

# 检测 Linux 发行版
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        VERSION="$VERSION_ID"
    elif command -v lsb_release &> /dev/null; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VERSION=$(lsb_release -sr)
    else
        print_error "无法检测 Linux 发行版"
        exit 1
    fi
    
    print_info "检测到系统: $DISTRO $VERSION"
}

# 安装系统依赖
install_system_deps() {
    print_step "安装系统依赖..."
    
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y python3 python3-pip python3-venv python3-dev \
                               curl wget git build-essential \
                               libasound2-dev portaudio19-dev \
                               libffi-dev libssl-dev \
                               chromium-browser || chromium || google-chrome-stable
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum update -y || sudo dnf update -y
            sudo yum install -y python3 python3-pip python3-devel \
                               curl wget git gcc gcc-c++ make \
                               alsa-lib-devel portaudio-devel \
                               openssl-devel libffi-devel \
                               chromium || google-chrome-stable
            ;;
        fedora)
            sudo dnf update -y
            sudo dnf install -y python3 python3-pip python3-devel \
                               curl wget git gcc gcc-c++ make \
                               alsa-lib-devel portaudio-devel \
                               openssl-devel libffi-devel \
                               chromium google-chrome-stable
            ;;
        arch|manjaro)
            sudo pacman -Sy
            sudo pacman -S --noconfirm python python-pip \
                                       curl wget git base-devel \
                                       alsa-lib portaudio \
                                       openssl libffi \
                                       chromium google-chrome
            ;;
        opensuse*|sles)
            sudo zypper refresh
            sudo zypper install -y python3 python3-pip python3-devel \
                                   curl wget git gcc gcc-c++ make \
                                   alsa-devel portaudio-devel \
                                   openssl-devel libffi-devel \
                                   chromium google-chrome-stable
            ;;
        *)
            print_warning "未知的 Linux 发行版: $DISTRO"
            print_info "请手动安装以下依赖:"
            print_info "- Python 3.8+"
            print_info "- pip, curl, wget, git"
            print_info "- 构建工具 (gcc, make 等)"
            print_info "- 音频库 (alsa-lib, portaudio)"
            print_info "- Chromium 或 Google Chrome"
            ;;
    esac
}

# 切换到项目目录
cd "$PROJECT_ROOT"

print_step "NagaAgent 3.0 Linux 环境配置开始..."

# 检测发行版
detect_distro

# 检查 Python 版本
print_step "检查 Python 版本..."
if ! command -v python3 &> /dev/null; then
    print_step "安装 Python..."
    install_system_deps
fi

PYTHON_VERSION=$(python3 --version | grep -o '[0-9]\+\.[0-9]\+')
if [[ "$(printf '%s\n' "$PYTHON_MIN_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$PYTHON_MIN_VERSION" ]]; then
    print_error "需要 Python $PYTHON_MIN_VERSION 或更高版本，当前版本: $PYTHON_VERSION"
    exit 1
fi

print_success "Python 版本检查通过: $PYTHON_VERSION"

# 安装系统依赖
install_system_deps

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

# 创建启动脚本
print_step "创建启动脚本..."
cat > start_linux.sh << 'EOF'
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
EOF

chmod +x start_linux.sh

print_success "✨ NagaAgent 3.0 Linux 环境配置完成！"
echo ""
print_info "🎯 启动应用："
echo "   ./start_linux.sh"
echo ""
print_info "📚 可选操作："
echo "   python -m playwright install firefox   # 安装 Firefox 驱动"
echo "   python -m playwright install webkit    # 安装 WebKit 驱动"
echo ""
print_info "🔧 故障排除："
echo "   如遇到依赖问题，请运行: uv sync --reload"
echo "   如遇到权限问题，请运行: chmod +x setup_linux.sh start_linux.sh"
echo "   如遇到音频问题，请检查 ALSA/PulseAudio 配置" 