#!/bin/bash

# TxAgent AMD GPU 安装脚本
# 适用于 AMD ROCm GPU

echo "🚀 开始安装 TxAgent AMD GPU 版本..."

# 检查系统
echo "📋 检查系统环境..."
if ! command -v rocm-smi &> /dev/null; then
    echo "❌ ROCm 未安装，请先安装 ROCm 驱动"
    echo "参考: https://rocm.docs.amd.com/en/latest/deploy/linux/quick_start.html"
    exit 1
fi

# 设置环境变量
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HSA_PATH=/opt/rocm
export PYTORCH_ROCM_ARCH="gfx906;gfx908;gfx90a;gfx1030;gfx1100"

echo "🔧 设置 ROCm 环境变量..."
echo "ROCM_PATH: $ROCM_PATH"
echo "HIP_PATH: $HIP_PATH"

# 升级 pip
echo "📦 升级 pip..."
pip install --upgrade pip setuptools wheel

# 安装 Rust (解决 outlines_core 编译问题)
echo "🦀 安装 Rust 编译器..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
fi

# 安装 PyTorch ROCm 6.2 版本
echo "🔥 安装 PyTorch ROCm 6.2 版本..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

# 安装 TxAgent (基础依赖)
echo "🤖 安装 TxAgent 基础依赖..."
pip install -e . --no-deps

# 安装其他依赖
echo "📚 安装其他依赖..."
pip install transformers>=4.30.0
pip install accelerate>=0.20.0
pip install sentence-transformers
pip install gradio
pip install numpy jinja2 typing-extensions

# 安装 vLLM (ROCm 版本)
echo "⚡ 安装 vLLM ROCm 版本..."
# 对于 MI300X，使用最新的 vLLM 版本
pip install vllm --no-build-isolation

# 安装 ToolUniverse
echo "🛠️ 安装 ToolUniverse..."
pip install tooluniverse

# 验证安装
echo "✅ 验证安装..."
python -c "
import torch
print(f'PyTorch 版本: {torch.__version__}')
print(f'ROCm 可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU 设备数量: {torch.cuda.device_count()}')
    print(f'当前 GPU: {torch.cuda.get_device_name(0)}')
else:
    print('⚠️  GPU 不可用，请检查 ROCm 安装')
"

echo "🎉 安装完成！"
echo "💡 如果遇到问题，请检查："
echo "   1. ROCm 驱动是否正确安装"
echo "   2. 环境变量是否正确设置"
echo "   3. GPU 是否被正确识别"
