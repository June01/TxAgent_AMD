# TxAgent AMD GPU 版本

这是 TxAgent 的 AMD GPU 兼容版本，专门为 AMD ROCm GPU（特别是 MI300X）优化。

## 🚀 主要特性

- ✅ **AMD ROCm 6.2 支持**：完全兼容最新的 ROCm 6.2 驱动
- ✅ **MI300X 优化**：专门针对 AMD MI300X GPU 进行优化
- ✅ **GPU 兼容层**：自动检测 CUDA/ROCm GPU 并使用相应的优化
- ✅ **简化安装**：提供多种安装脚本，适应不同环境
- ✅ **故障排除**：详细的故障排除指南和调试工具

## 📦 快速安装

### 方法1：一键安装（推荐）

```bash
# 下载并运行快速安装脚本
chmod +x quick_install_rocm62.sh
./quick_install_rocm62.sh
```

### 方法2：手动安装

```bash
H100 环境配置：
vi  /usr/local/lib/python3.11/dist-packages/txagent/txagent.py
self.model = LLM(
    model=self.model_name,
    gpu_memory_utilization=0.70,  # 稍低于量化方案
    max_model_len=32768,           # 32K上下文（FP16下更安全）
    quantization=None,             # 禁用量化
    tensor_parallel_size=1,
    dtype="float16",               # 保持FP16
    enable_chunked_prefill=True,
    max_num_batched_tokens=16384,  # 降低批处理规模
    max_num_seqs=6,                # 减少并行序列数
    block_size=16,
    swap_space=16,
)

AMD mi300 环境配置：
所有操作在docker 内部操作：

docker pull rocm/vllm:rocm6.3.1_vllm_0.8.5_20250513

= b07754949af6

docker run -it \
   --network=host \
   --group-add=video \
   --ipc=host \
   --cap-add=SYS_PTRACE \
   --security-opt seccomp=unconfined \
   --device /dev/kfd \
   --device /dev/dri \
   -v /root/TxAgent:/app/model \
   b07754949af6 \
   bash


在docker 内部安装环境

git clone https://github.com/mims-harvard/TxAgent.git

cd  TxAgent

pip install .
#如果有cuda 报错，删除，应该不会报错；


pip install tooluniverse




python run.py --config metadata_config_test_txagentfp16.json

python -c "import torch; print(f'PyTorch {torch.__version__}, ROCm {torch.version.hip}')"


# 1. 共享会话（两人同时操作）
screen -S shared_session  # 主机创建
screen -x shared_session  # 另一终端接入

# 2. 记录所有操作（审计/复盘）
screen -L -S record_session  # 日志存screenlog.0

# 3. 分屏操作（需编译时启用）
Ctrl+a → |    # 垂直分屏
Ctrl+a → Tab  # 切换分屏



```

## 🔧 环境要求

- **硬件**：AMD GPU（推荐 MI300X）
- **驱动**：ROCm 6.2+
- **Python**：3.8+
- **内存**：建议 32GB+ 系统内存，80GB+ GPU 内存

## 📋 支持的 GPU

### 完全支持

- ✅ AMD Instinct MI300X (gfx942)
- ✅ AMD Instinct MI250X (gfx90a)
- ✅ AMD Instinct MI100 (gfx908)

### 部分支持

- ⚠️ AMD Radeon RX 7000 系列
- ⚠️ AMD Radeon RX 6000 系列

## 🛠️ 使用方法

### 基本使用

```python
from txagent import TxAgent

# 初始化 TxAgent
agent = TxAgent(
    model_name="mims-harvard/TxAgent-T1-Llama-3.1-8B",
    rag_model_name="mims-harvard/ToolRAG-T1-GTE-Qwen2-1.5B",
    enable_summary=False,
    avoid_repeat=False
)

# 初始化模型
agent.init_model()

# 运行推理
question = "患者50岁，有中度肝功能损害，使用新药时如何调整剂量？"
response = agent.run_multistep_agent(
    question,
    temperature=0.3,
    max_new_tokens=1024,
    max_token=90240,
    max_round=20
)

print(response)
```

### 检查 GPU 状态

```python
from src.txagent.gpu_utils import print_gpu_info, is_gpu_available

# 打印 GPU 信息
print_gpu_info()

# 检查 GPU 是否可用
if is_gpu_available():
    print("✅ GPU 可用")
else:
    print("❌ GPU 不可用")
```

## 🔍 故障排除

### 常见问题

1. **PyTorch 无法识别 GPU**

   ```bash
   # 检查环境变量
   echo $ROCM_PATH
   source ~/.txagent_rocm62_env
   ```
2. **vLLM 安装失败**

   ```bash
   # 尝试无缓存安装
   pip install vllm --no-cache-dir --no-build-isolation
   ```
3. **outlines_core 编译错误**

   ```bash
   # 安装 Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source ~/.cargo/env
   ```

### 详细故障排除

请参考 [AMD_GPU_TROUBLESHOOTING.md](AMD_GPU_TROUBLESHOOTING.md) 获取详细的故障排除指南。

## 📊 性能优化

### 环境变量优化

```bash
export HSA_FORCE_FINE_GRAIN_PCIE=1
export HIP_FORCE_DEV_KERNARG=1
export PYTORCH_HIP_ALLOC_CONF=max_split_size_mb:128
```

### 模型配置优化

```python
agent = TxAgent(
    model_name,
    rag_model_name,
    enable_summary=False,
    avoid_repeat=True,      # 启用重复避免
    step_rag_num=5,         # 减少 RAG 步数
    max_round=10            # 减少推理轮数
)
```

## 🆚 与原版差异

| 特性       | 原版 (CUDA) | AMD 版本 (ROCm) |
| ---------- | ----------- | --------------- |
| GPU 支持   | NVIDIA CUDA | AMD ROCm        |
| 安装复杂度 | 简单        | 中等            |
| 性能       | 优秀        | 良好            |
| 兼容性     | 广泛        | 特定硬件        |
| 内存管理   | 自动        | 需要优化        |

## 📁 文件结构

```
TxAgent_AMD/
├── src/txagent/
│   ├── gpu_utils.py           # GPU 兼容层
│   ├── txagent.py            # 主要修改
│   └── toolrag.py            # RAG 模块修改
├── install_rocm62.sh         # ROCm 6.2 安装脚本
├── quick_install_rocm62.sh   # 快速安装脚本
├── amd_gpu_config.py         # AMD GPU 配置
├── AMD_GPU_TROUBLESHOOTING.md # 故障排除指南
└── README_AMD.md             # 本文件
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进 AMD GPU 支持！

## 📄 许可证

与原版 TxAgent 相同的许可证。

## 🔗 相关链接

- [原版 TxAgent](https://github.com/mims-harvard/TxAgent)
- [AMD ROCm 文档](https://rocm.docs.amd.com/)
- [PyTorch ROCm 支持](https://pytorch.org/get-started/locally/)

---

**注意**：这是一个社区维护的 AMD GPU 兼容版本，不是官方版本。使用前请确保您的硬件和驱动程序兼容。
