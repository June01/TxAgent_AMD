#!/bin/bash

# TxAgent MI300X 快速安装脚本
# 专为 AMD MI300X GPU 优化

echo "🚀 开始安装 TxAgent MI300X 版本..."

# 检查当前环境
echo "📋 检查当前环境..."
echo "Python 版本: $(python --version)"
echo "Pip 版本: $(pip --version)"

# 检查 ROCm
if command -v rocm-smi &> /dev/null; then
    echo "✅ ROCm 已安装"
    rocm-smi
else
    echo "⚠️  ROCm 未检测到，但在容器环境中可能正常"
fi

# 设置环境变量（MI300X 优化）
echo "🔧 设置 MI300X 环境变量..."
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HSA_PATH=/opt/rocm
export PYTORCH_ROCM_ARCH="gfx942"  # MI300X 架构
export HIP_VISIBLE_DEVICES=0
export HSA_FORCE_FINE_GRAIN_PCIE=1

# 升级 pip 和基础工具
echo "📦 升级 pip..."
pip install --upgrade pip setuptools wheel

# 安装 Rust（如果需要）
echo "🦀 检查 Rust..."
if ! command -v rustc &> /dev/null; then
    echo "安装 Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
else
    echo "✅ Rust 已安装"
fi

# 安装 PyTorch ROCm 版本（MI300X 兼容）
echo "🔥 安装 PyTorch ROCm 版本..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0

# 验证 PyTorch 安装
echo "🔍 验证 PyTorch 安装..."
python -c "
import torch
print(f'PyTorch 版本: {torch.__version__}')
print(f'CUDA 可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'设备数量: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'设备 {i}: {torch.cuda.get_device_name(i)}')
"

# 安装基础依赖
echo "📚 安装基础依赖..."
pip install numpy jinja2 typing-extensions
pip install transformers>=4.30.0
pip install accelerate>=0.20.0
pip install sentence-transformers
pip install gradio

# 安装 TxAgent（跳过依赖检查）
echo "🤖 安装 TxAgent..."
pip install -e . --no-deps

# 安装 ToolUniverse
echo "🛠️ 安装 ToolUniverse..."
pip install tooluniverse

# 尝试安装 vLLM
echo "⚡ 安装 vLLM..."
pip install vllm --no-build-isolation || {
    echo "⚠️  vLLM 安装失败，尝试替代方案..."
    pip install vllm --no-cache-dir --no-build-isolation || {
        echo "❌ vLLM 安装失败，请手动安装"
    }
}

# 设置运行时环境变量
echo "🔧 设置运行时环境..."
cat > ~/.txagent_env << 'EOF'
# TxAgent MI300X 环境变量
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HSA_PATH=/opt/rocm
export PYTORCH_ROCM_ARCH="gfx942"
export HIP_VISIBLE_DEVICES=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export VLLM_USE_V1=0
export TOKENIZERS_PARALLELISM=false
export MKL_THREADING_LAYER=GNU
EOF

echo "环境变量已保存到 ~/.txagent_env"
echo "使用前请运行: source ~/.txagent_env"

# 最终验证
echo "✅ 验证安装..."
python -c "
try:
    from txagent import TxAgent
    print('✅ TxAgent 导入成功')
except ImportError as e:
    print(f'❌ TxAgent 导入失败: {e}')

try:
    import torch
    if torch.cuda.is_available():
        print('✅ GPU 可用')
        x = torch.randn(10, 10).cuda()
        y = torch.mm(x, x.t())
        print('✅ GPU 计算测试成功')
    else:
        print('⚠️  GPU 不可用')
except Exception as e:
    print(f'❌ GPU 测试失败: {e}')
"

echo "🎉 安装完成！"
echo ""
echo "📝 使用说明："
echo "1. 运行: source ~/.txagent_env"
echo "2. 测试: python run_example.py"
echo ""
echo "💡 如果遇到问题："
echo "- 检查 ROCm 版本: rocm-smi"
echo "- 检查 GPU: python -c 'import torch; print(torch.cuda.is_available())'"
echo "- 查看日志获取详细错误信息"
