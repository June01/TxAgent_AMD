"""
AMD GPU 配置文件
设置 ROCm 环境变量和优化参数
"""

import os
import sys


def setup_amd_gpu_environment():
    """设置AMD GPU环境变量"""

    # ROCm 基础路径
    rocm_path = os.environ.get("ROCM_PATH", "/opt/rocm")

    # 设置 ROCm 环境变量
    env_vars = {
        "ROCM_PATH": rocm_path,
        "HIP_PATH": rocm_path,
        "HSA_PATH": rocm_path,
        "LD_LIBRARY_PATH": f"{rocm_path}/lib:{os.environ.get('LD_LIBRARY_PATH', '')}",
        "PATH": f"{rocm_path}/bin:{os.environ.get('PATH', '')}",
        # ROCm 6.2 性能优化
        "HSA_FORCE_FINE_GRAIN_PCIE": "1",
        "HIP_VISIBLE_DEVICES": "0",
        "ROCM_TARGET_LST": "gfx906;gfx908;gfx90a;gfx942;gfx1030;gfx1100",  # 添加 gfx942 (MI300X)
        # PyTorch ROCm 6.2 优化
        "PYTORCH_ROCM_ARCH": "gfx906;gfx908;gfx90a;gfx942;gfx1030;gfx1100",  # 添加 gfx942
        "HIP_FORCE_DEV_KERNARG": "1",
        # vLLM ROCm 优化
        "VLLM_USE_ROCM": "1",
        "VLLM_USE_V1": "0",  # 禁用 V1 API
        # 内存优化
        "PYTORCH_HIP_ALLOC_CONF": "max_split_size_mb:128",
        "HIP_LAUNCH_BLOCKING": "0",
        # 调试选项（可选）
        # 'HIP_PRINT_STATS': '1',
        # 'AMD_LOG_LEVEL': '3',
    }

    # 应用环境变量
    for key, value in env_vars.items():
        os.environ[key] = value
        print(f"设置环境变量: {key}={value}")

    # 验证 ROCm 安装
    try:
        import subprocess

        result = subprocess.run(
            ["rocm-smi"], capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            print("✅ ROCm 安装验证成功")
            print("GPU 信息:")
            print(result.stdout)
        else:
            print("⚠️  ROCm 验证失败，请检查安装")
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        print(f"⚠️  无法验证 ROCm 安装: {e}")

    return True


def check_amd_gpu_compatibility():
    """检查AMD GPU兼容性"""
    try:
        import torch

        print("🔍 检查 PyTorch ROCm 支持...")
        print(f"PyTorch 版本: {torch.__version__}")
        print(f"ROCm 可用: {torch.cuda.is_available()}")

        if torch.cuda.is_available():
            print(f"GPU 设备数量: {torch.cuda.device_count()}")
            for i in range(torch.cuda.device_count()):
                print(f"设备 {i}: {torch.cuda.get_device_name(i)}")

            # 测试简单的 GPU 操作
            try:
                x = torch.randn(100, 100).cuda()
                y = torch.mm(x, x.t())
                print("✅ GPU 计算测试成功")

                # 清理测试张量
                del x, y
                torch.cuda.empty_cache()

            except Exception as e:
                print(f"❌ GPU 计算测试失败: {e}")
                return False
        else:
            print("❌ 没有检测到可用的 GPU")
            return False

    except ImportError as e:
        print(f"❌ PyTorch 导入失败: {e}")
        return False

    return True


def optimize_for_txagent():
    """为 TxAgent 优化 AMD GPU 设置"""

    # TxAgent 特定优化
    txagent_env = {
        # 模型加载优化
        "TRANSFORMERS_CACHE": os.path.expanduser("~/.cache/huggingface/transformers"),
        "HF_HOME": os.path.expanduser("~/.cache/huggingface"),
        # 内存管理
        "TOKENIZERS_PARALLELISM": "false",
        "MKL_THREADING_LAYER": "GNU",
        # vLLM 优化
        "VLLM_ATTENTION_BACKEND": "ROCM_FLASH",
        "VLLM_WORKER_MULTIPROC_METHOD": "spawn",
    }

    for key, value in txagent_env.items():
        os.environ[key] = value
        print(f"TxAgent 优化: {key}={value}")


def main():
    """主函数：设置完整的 AMD GPU 环境"""
    print("🚀 配置 TxAgent AMD GPU 环境...")

    # 设置基础环境
    setup_amd_gpu_environment()

    # TxAgent 特定优化
    optimize_for_txagent()

    # 兼容性检查
    if check_amd_gpu_compatibility():
        print("🎉 AMD GPU 环境配置成功！")
        return True
    else:
        print("❌ AMD GPU 环境配置失败，请检查安装")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
