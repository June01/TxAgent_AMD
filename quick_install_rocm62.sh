#!/bin/bash

# TxAgent ROCm 6.2 快速安装命令
echo "🚀 TxAgent ROCm 6.2 快速安装..."

# 设置环境变量
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export PYTORCH_ROCM_ARCH="gfx942"  # MI300X
export VLLM_USE_V1=0
export TOKENIZERS_PARALLELISM=false

# 1. 升级 pip
echo "📦 升级 pip..."
pip install --upgrade pip setuptools wheel

# 2. 安装 Rust (解决 outlines_core 编译问题)
echo "🦀 安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# 3. 安装 PyTorch ROCm 6.2
echo "🔥 安装 PyTorch ROCm 6.2..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

# 4. 安装 TxAgent (跳过依赖检查)
echo "🤖 安装 TxAgent..."
pip install -e . --no-deps

# 5. 安装其他依赖
echo "📚 安装依赖..."
pip install transformers>=4.30.0 accelerate>=0.20.0 sentence-transformers gradio numpy jinja2 typing-extensions tooluniverse

# 6. 安装 vLLM
echo "⚡ 安装 vLLM..."
pip install vllm --no-build-isolation

# 7. 验证安装
echo "✅ 验证安装..."
python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'GPU可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
try:
    from txagent import TxAgent
    print('✅ TxAgent 导入成功')
except Exception as e:
    print(f'❌ TxAgent 导入失败: {e}')
"

echo "🎉 安装完成！运行: python run_example.py"
