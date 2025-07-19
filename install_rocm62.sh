#!/bin/bash

# TxAgent ROCm 6.2 快速安装脚本
# 专为已安装 ROCm 6.2 的环境优化

echo "🚀 开始安装 TxAgent (ROCm 6.2)..."

# 检查 ROCm 6.2
echo "📋 检查 ROCm 6.2 环境..."
if command -v rocm-smi &> /dev/null; then
    echo "✅ ROCm 已安装"
    rocm_version=$(rocm-smi --showproductname | head -1)
    echo "ROCm 信息: $rocm_version"
    rocm-smi
else
    echo "❌ ROCm 未检测到，请确认安装"
    exit 1
fi

# 设置 ROCm 6.2 环境变量
echo "🔧 设置 ROCm 6.2 环境变量..."
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HSA_PATH=/opt/rocm
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export PATH=/opt/rocm/bin:$PATH

# MI300X 特定设置
export PYTORCH_ROCM_ARCH="gfx942"  # MI300X
export HIP_VISIBLE_DEVICES=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export HIP_FORCE_DEV_KERNARG=1

# vLLM 和 TxAgent 优化
export VLLM_USE_V1=0
export TOKENIZERS_PARALLELISM=false
export MKL_THREADING_LAYER=GNU

echo "环境变量设置完成"

# 升级 pip
echo "📦 升级 pip..."
pip install --upgrade pip setuptools wheel

# 安装 Rust（解决 outlines_core 编译问题）
echo "🦀 检查 Rust..."
if ! command -v rustc &> /dev/null; then
    echo "安装 Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    echo "✅ Rust 安装完成"
else
    echo "✅ Rust 已安装: $(rustc --version)"
fi

# 安装 PyTorch ROCm 6.2 版本
echo "🔥 安装 PyTorch ROCm 6.2 版本..."
pip uninstall -y torch torchvision torchaudio  # 清理旧版本
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2

# 验证 PyTorch 安装
echo "🔍 验证 PyTorch 安装..."
python -c "
import torch
print(f'PyTorch 版本: {torch.__version__}')
print(f'ROCm 编译版本: {torch.version.hip if hasattr(torch.version, \"hip\") else \"未知\"}')
print(f'CUDA 可用 (实际是ROCm): {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'设备数量: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'设备 {i}: {torch.cuda.get_device_name(i)}')
        
    # 简单的 GPU 测试
    try:
        x = torch.randn(100, 100).cuda()
        y = torch.mm(x, x.t())
        print('✅ GPU 计算测试成功')
        del x, y
        torch.cuda.empty_cache()
    except Exception as e:
        print(f'❌ GPU 计算测试失败: {e}')
else:
    print('❌ GPU 不可用')
"

# 安装基础依赖
echo "📚 安装基础依赖..."
pip install numpy jinja2 typing-extensions
pip install transformers>=4.30.0
pip install accelerate>=0.20.0
pip install sentence-transformers
pip install gradio

# 安装 TxAgent（跳过依赖检查避免冲突）
echo "🤖 安装 TxAgent..."
pip install -e . --no-deps

# 安装 ToolUniverse
echo "🛠️ 安装 ToolUniverse..."
pip install tooluniverse

# 安装 vLLM（ROCm 6.2 兼容版本）
echo "⚡ 安装 vLLM..."
# 对于 ROCm 6.2，使用最新版本的 vLLM
pip install vllm --no-build-isolation || {
    echo "⚠️  标准安装失败，尝试无缓存安装..."
    pip install vllm --no-cache-dir --no-build-isolation || {
        echo "⚠️  vLLM 安装失败，尝试从源码安装..."
        pip install git+https://github.com/vllm-project/vllm.git --no-build-isolation || {
            echo "❌ vLLM 安装失败，请手动处理"
        }
    }
}

# 保存环境变量到文件
echo "💾 保存环境配置..."
cat > ~/.txagent_rocm62_env << 'EOF'
# TxAgent ROCm 6.2 环境变量
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HSA_PATH=/opt/rocm
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export PATH=/opt/rocm/bin:$PATH

# MI300X 优化
export PYTORCH_ROCM_ARCH="gfx942"
export HIP_VISIBLE_DEVICES=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export HIP_FORCE_DEV_KERNARG=1

# TxAgent 优化
export VLLM_USE_V1=0
export TOKENIZERS_PARALLELISM=false
export MKL_THREADING_LAYER=GNU

# 内存优化
export PYTORCH_HIP_ALLOC_CONF=max_split_size_mb:128
export HIP_LAUNCH_BLOCKING=0
EOF

echo "环境变量已保存到 ~/.txagent_rocm62_env"

# 最终验证
echo "✅ 最终验证..."
source ~/.txagent_rocm62_env

python -c "
print('🔍 验证安装状态...')

# 检查 TxAgent
try:
    from txagent import TxAgent
    print('✅ TxAgent 导入成功')
except ImportError as e:
    print(f'❌ TxAgent 导入失败: {e}')

# 检查 ToolUniverse
try:
    from tooluniverse import ToolUniverse
    print('✅ ToolUniverse 导入成功')
except ImportError as e:
    print(f'❌ ToolUniverse 导入失败: {e}')

# 检查 vLLM
try:
    import vllm
    print(f'✅ vLLM 导入成功: {vllm.__version__}')
except ImportError as e:
    print(f'❌ vLLM 导入失败: {e}')

# GPU 测试
try:
    import torch
    if torch.cuda.is_available():
        print('✅ GPU 可用')
        device_name = torch.cuda.get_device_name(0)
        print(f'GPU 设备: {device_name}')
        
        # 内存测试
        allocated = torch.cuda.memory_allocated() / 1024**3
        reserved = torch.cuda.memory_reserved() / 1024**3
        print(f'GPU 内存 - 已分配: {allocated:.2f}GB, 已保留: {reserved:.2f}GB')
        
    else:
        print('❌ GPU 不可用')
except Exception as e:
    print(f'❌ GPU 检查失败: {e}')
"

echo ""
echo "🎉 安装完成！"
echo ""
echo "📝 使用说明："
echo "1. 加载环境: source ~/.txagent_rocm62_env"
echo "2. 运行测试: python run_example.py"
echo ""
echo "🔧 如果遇到问题："
echo "- 检查 GPU: rocm-smi"
echo "- 检查 PyTorch: python -c 'import torch; print(torch.cuda.is_available())'"
echo "- 重新加载环境: source ~/.txagent_rocm62_env"
echo ""
echo "💡 MI300X 优化已启用，包括："
echo "- gfx942 架构支持"
echo "- 内存优化配置"
echo "- vLLM ROCm 6.2 兼容性"
