#!/bin/bash
# NagaAgent 3.0 macOS 一键部署脚本
# 自动安装所有必需的系统依赖和 Python 环境

set -e

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

print_step "NagaAgent 3.0 macOS 一键部署开始..."

# 检查并安装 Homebrew
print_step "检查 Homebrew..."
if ! command -v brew &> /dev/null; then
    print_step "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # 配置 Homebrew 环境变量
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    print_success "Homebrew 已安装"
fi

# 检查并安装 Python 3.11
print_step "检查 Python 环境..."
if ! command -v python3 &> /dev/null || [[ "$(python3 --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)" < "3.8" ]]; then
    print_step "安装 Python 3.11..."
    brew install python@3.11
    
    # 创建软链接（如果需要）
    if [[ ! -L "/usr/local/bin/python3" ]] && [[ -f "/opt/homebrew/bin/python3.11" ]]; then
        print_info "创建 Python 软链接..."
        sudo ln -sf /opt/homebrew/bin/python3.11 /usr/local/bin/python3
    fi
else
    print_success "Python 环境已准备就绪"
fi

# 检查并安装 uv
print_step "检查 uv 包管理器..."
if ! command -v uv &> /dev/null; then
    print_step "正在安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # 刷新环境变量
    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v uv &> /dev/null; then
        print_success "uv 安装成功"
    else
        print_warning "uv 安装失败，后续将使用 pip 方式"
    fi
else
    print_success "uv 已安装"
fi

# 安装系统依赖
print_step "安装系统依赖..."

# PortAudio (语音功能依赖)
if ! brew list portaudio &> /dev/null 2>&1; then
    print_step "安装 PortAudio (语音功能)..."
    brew install portaudio
else
    print_success "PortAudio 已安装"
fi

# Google Chrome (浏览器自动化)
if [[ ! -d "/Applications/Google Chrome.app" ]]; then
    print_step "安装 Google Chrome..."
    brew install --cask google-chrome
else
    print_success "Google Chrome 已安装"
fi

# 检查项目权限
print_step "设置脚本权限..."
chmod +x setup_mac.sh start_mac.sh

# 执行主要环境配置
print_step "执行环境配置..."
./setup_mac.sh

print_success "✨ NagaAgent 3.0 macOS 一键部署完成！"
echo ""
print_info "🎯 启动应用："
echo "   ./start_mac.sh"
echo ""
print_info "📚 可选操作："
echo "   brew install --cask firefox          # 安装 Firefox"
echo "   brew install --cask microsoft-edge   # 安装 Edge"
echo ""
print_info "🔧 故障排除："
echo "   如遇到权限问题，请运行: chmod +x *.sh"
echo "   如遇到依赖问题，请运行: ./setup_mac.sh"
echo ""
print_info "📖 查看详细文档："
echo "   open README.md"