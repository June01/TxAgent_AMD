# TxAgent AMD GPU 故障排除指南

## 🚀 快速开始

### 1. 安装 ROCm 驱动
```bash
# Ubuntu/Debian
wget https://repo.radeon.com/amdgpu-install/latest/ubuntu/jammy/amdgpu-install_5.7.50700-1_all.deb
sudo dpkg -i amdgpu-install_5.7.50700-1_all.deb
sudo amdgpu-install --usecase=rocm

# 重启系统
sudo reboot
```

### 2. 验证 ROCm 安装
```bash
# 检查 ROCm 版本
rocm-smi
/opt/rocm/bin/rocminfo

# 检查 GPU 设备
lspci | grep -i amd
```

### 3. 安装 TxAgent AMD 版本
```bash
# 使用提供的安装脚本
chmod +x install_amd_gpu.sh
./install_amd_gpu.sh

# 或手动安装
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.7
pip install -e .
```

## 🔧 常见问题解决

### 问题1: `outlines_core` 编译失败
**错误信息**: `error: can't find Rust compiler`

**解决方案**:
```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 重新安装
pip install --upgrade pip
pip install outlines_core --no-cache-dir
```

### 问题2: PyTorch 无法识别 AMD GPU
**错误信息**: `torch.cuda.is_available()` 返回 `False`

**解决方案**:
```bash
# 检查环境变量
echo $ROCM_PATH
echo $HIP_PATH

# 设置环境变量
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH

# 重新安装 PyTorch ROCm 版本
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.7
```

### 问题3: vLLM 不支持 ROCm
**错误信息**: vLLM 相关的 CUDA 错误

**解决方案**:
```bash
# 检查 vLLM ROCm 支持
pip install vllm --no-build-isolation

# 如果仍有问题，从源码编译
git clone https://github.com/vllm-project/vllm.git
cd vllm
pip install -e . --no-build-isolation
```

### 问题4: 内存不足错误
**错误信息**: `CUDA out of memory` 或类似错误

**解决方案**:
```python
# 在代码中添加内存优化
import os
os.environ['PYTORCH_HIP_ALLOC_CONF'] = 'max_split_size_mb:128'

# 或者减少模型大小/批处理大小
agent = TxAgent(
    model_name,
    rag_model_name,
    enable_summary=False,
    avoid_repeat=False
)
```

### 问题5: 性能较慢
**解决方案**:
```bash
# 设置性能优化环境变量
export HSA_FORCE_FINE_GRAIN_PCIE=1
export HIP_FORCE_DEV_KERNARG=1
export PYTORCH_ROCM_ARCH=gfx906;gfx908;gfx90a;gfx1030;gfx1100

# 使用配置脚本
python amd_gpu_config.py
```

## 🔍 调试工具

### 检查 GPU 状态
```bash
# ROCm 系统监控
rocm-smi

# 详细 GPU 信息
rocminfo

# 内存使用情况
rocm-smi --showmeminfo
```

### Python 调试代码
```python
import torch
from src.txagent.gpu_utils import print_gpu_info

# 打印 GPU 信息
print_gpu_info()

# 测试 GPU 计算
if torch.cuda.is_available():
    x = torch.randn(100, 100).cuda()
    y = torch.mm(x, x.t())
    print("✅ GPU 计算正常")
else:
    print("❌ GPU 不可用")
```

## 📋 支持的 AMD GPU

### 完全支持
- AMD Radeon RX 6000 系列 (RDNA2)
- AMD Radeon RX 7000 系列 (RDNA3)
- AMD Instinct MI100/MI200 系列

### 部分支持
- AMD Radeon RX 5000 系列 (RDNA1)
- 较老的 GCN 架构 GPU

### 检查 GPU 架构
```bash
rocminfo | grep "Name:"
rocminfo | grep "Compute Unit:"
```

## 🛠️ 性能优化建议

### 1. 环境变量优化
```bash
export HSA_FORCE_FINE_GRAIN_PCIE=1
export HIP_VISIBLE_DEVICES=0
export PYTORCH_HIP_ALLOC_CONF=max_split_size_mb:128
```

### 2. 模型配置优化
```python
# 减少内存使用
agent = TxAgent(
    model_name,
    rag_model_name,
    enable_summary=False,
    avoid_repeat=True,  # 启用重复避免
    step_rag_num=5      # 减少 RAG 步数
)
```

### 3. 推理参数优化
```python
response = agent.run_multistep_agent(
    question,
    temperature=0.3,
    max_new_tokens=512,  # 减少生成长度
    max_token=45120,     # 减少最大令牌数
    max_round=10         # 减少推理轮数
)
```

## 📞 获取帮助

如果遇到其他问题：

1. **检查日志**: 查看详细的错误信息
2. **环境信息**: 运行 `python amd_gpu_config.py` 获取环境报告
3. **社区支持**: 
   - ROCm GitHub: https://github.com/RadeonOpenCompute/ROCm
   - PyTorch ROCm: https://pytorch.org/get-started/locally/
   - vLLM Issues: https://github.com/vllm-project/vllm/issues

## 🔄 版本兼容性

| 组件 | 推荐版本 | ROCm 版本 |
|------|----------|-----------|
| ROCm | 5.7+ | 5.7.0 |
| PyTorch | 2.0+ | rocm5.7 |
| vLLM | 0.3.0+ | 最新 |
| Python | 3.8+ | - |

定期更新这些组件以获得最佳性能和兼容性。
