# NagaAgent 3.0 Windows 环境配置脚本
# 使用 uv 作为主要包管理器，提供更快的依赖安装体验

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# 配置参数
$PYTHON_MIN_VERSION = "3.8"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = $SCRIPT_DIR

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    $colors = @{
        "Red" = "91"; "Green" = "92"; "Yellow" = "93"; "Blue" = "94"; "Magenta" = "95"; "Cyan" = "96"; "White" = "97"
    }
    if ($colors.ContainsKey($Color)) {
        Write-Host "$([char]27)[$($colors[$Color])m$Message$([char]27)[0m"
    } else {
        Write-Host $Message
    }
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "🚀 $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️ $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

# 切换到项目目录
Set-Location $PROJECT_ROOT

Write-Step "NagaAgent 3.0 Windows 环境配置开始..."

# 检查 Python 版本
Write-Step "检查 Python 版本..."
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "未找到 Python，请先安装 Python $PYTHON_MIN_VERSION 或更高版本"
        Write-Host "下载链接: https://www.python.org/downloads/"
        exit 1
    }
    
    $versionNumber = ($pythonVersion -replace "Python ", "").Trim()
    if ([version]$versionNumber -lt [version]$PYTHON_MIN_VERSION) {
        Write-Error "需要 Python $PYTHON_MIN_VERSION 或更高版本，当前版本: $versionNumber"
        exit 1
    }
    
    Write-Success "Python 版本检查通过: $versionNumber"
} catch {
    Write-Error "Python 版本检查失败: $($_.Exception.Message)"
    exit 1
}

# 检查并安装 uv
Write-Step "检查 uv 包管理器..."
if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
    Write-Step "正在安装 uv..."
    try {
        # 使用官方安装脚本
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # 验证安装
        if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
            Write-Warning "uv 自动安装失败，正在回退到 pip 方式..."
            $USE_UV = $false
        } else {
            Write-Success "uv 安装成功"
            $USE_UV = $true
        }
    } catch {
        Write-Warning "uv 安装失败，将使用 pip 方式: $($_.Exception.Message)"
        $USE_UV = $false
    }
} else {
    Write-Success "uv 已安装"
    $USE_UV = $true
}

# 使用 uv 或 pip 安装依赖
if ($USE_UV) {
    Write-Step "使用 uv 安装依赖（推荐方式）..."
    try {
        # uv 会自动管理虚拟环境
        uv sync
        Write-Success "uv 依赖安装完成"
    } catch {
        Write-Warning "uv 安装失败，回退到 pip 方式: $($_.Exception.Message)"
        $USE_UV = $false
    }
}

if (-not $USE_UV) {
    Write-Step "使用 pip 安装依赖..."
    
    # 创建虚拟环境
    if (-not (Test-Path ".venv")) {
        Write-Step "创建虚拟环境..."
        python -m venv .venv
    }
    
    # 激活虚拟环境
    Write-Step "激活虚拟环境..."
    & ".venv\Scripts\Activate.ps1"
    
    # 升级 pip
    Write-Step "升级 pip..."
    python -m pip install --upgrade pip
    
    # 安装依赖
    Write-Step "安装项目依赖..."
    pip install -e .
    
    Write-Success "pip 依赖安装完成"
}

# 安装 playwright 浏览器驱动
Write-Step "安装 playwright 浏览器驱动..."
try {
    if ($USE_UV) {
        uv run python -m playwright install chromium
    } else {
        python -m playwright install chromium
    }
    Write-Success "playwright 驱动安装完成"
} catch {
    Write-Warning "playwright 驱动安装失败，请手动运行: python -m playwright install chromium"
}

# 环境检查
Write-Step "执行环境检查..."
try {
    if ($USE_UV) {
        uv run python check_env.py
    } else {
        python check_env.py
    }
    Write-Success "环境检查通过"
} catch {
    Write-Warning "环境检查失败，请检查依赖安装是否完整"
}

Write-Success "✨ NagaAgent 3.0 Windows 环境配置完成！"
Write-Host ""
Write-ColorOutput "🎯 启动应用：" "Cyan"
Write-Host "   .\start.bat"
Write-Host ""
Write-ColorOutput "📚 可选操作：" "Cyan"
Write-Host "   python -m playwright install firefox   # 安装 Firefox 驱动"
Write-Host "   python -m playwright install webkit    # 安装 WebKit 驱动"
Write-Host ""
Write-ColorOutput "🔧 故障排除：" "Cyan"
Write-Host "   如遇到依赖问题，请运行: uv sync --reload"
Write-Host "   如遇到权限问题，请以管理员身份运行 PowerShell" 