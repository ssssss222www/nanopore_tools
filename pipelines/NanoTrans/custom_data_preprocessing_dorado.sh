#!/bin/bash
set -e -o pipefail

#######################################
# 1. 基础配置 (请根据你的实际情况修改这部分!)
#######################################

# [重要] 你的原始 fast5 文件所在的目录 (请使用绝对路径)
# 示例: raw_fast5_dir="/home/user/data/my_sample_fast5"
raw_fast5_dir="/path/to/your/raw_fast5_files" 

# [重要] 给你的样本起个名字 (输出文件会用到这个名字)
sample_id="MySample01"

# [可选] 运行模式: "cpu" (慢) 或 "cuda:0" (使用显卡, 快)
# 如果你有 NVIDIA 显卡并安装了驱动，建议改为 "cuda:0" 或 "cuda:all"
dorado_run_device="cpu" 

# [可选] 线程数
threads=8

#######################################
# 加载环境 (自动寻找项目根目录的 env.sh)
#######################################
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$PROJECT_DIR/env.sh" ]; then
    source "$PROJECT_DIR/env.sh"
else
    echo "Error: 找不到 env.sh 文件，请先运行 install_dependencies.sh 安装依赖！"
    exit 1
fi

#######################################
# 高级配置 (通常不需要修改)
#######################################
# RNA Basecalling 模型 (默认 rna002_70bps_hac@v3)
decode_models_name="rna002_70bps_hac@v3" 
# 质量过滤阈值
qual=5 

# 输出目录设置
basecalled_fastq_dir="$PROJECT_DIR/basecalled_fastq/$sample_id"
basecalled_summary_dir="$PROJECT_DIR/basecalled_summary/$sample_id"

#######################################
# GPU 环境配置 (如果使用 GPU)
#######################################
if [[ $dorado_run_device != "cpu" ]]; then
    gpu_bin_path="/public/software/cuda-11.4/bin"
    gpu_lib_path="/public/software/cuda-11.4/lib64"
    export PATH=$gpu_bin_path:$PATH
    export LD_LIBRARY_PATH=$gpu_lib_path:$LD_LIBRARY_PATH
fi

#######################################
# 开始处理
#######################################

echo "=========================================="
echo " 正在处理样本: $sample_id"
echo " 输入目录: $raw_fast5_dir"
echo " 输出目录: $basecalled_fastq_dir"
echo " 运行设备: $dorado_run_device"
echo "=========================================="

# 检查输入目录是否存在
if [ ! -d "$raw_fast5_dir" ]; then
    echo "错误: 找不到输入目录 $raw_fast5_dir"
    echo "请打开脚本修改 'raw_fast5_dir' 变量为正确的路径。"
    exit 1
fi

# 创建输出目录
mkdir -p "$basecalled_fastq_dir"
mkdir -p "$basecalled_summary_dir"

# 检查输出目录是否为空 (防止覆盖)
if [ "$(ls -A $basecalled_fastq_dir)" ]; then
   echo "警告: 输出目录 $basecalled_fastq_dir 不为空！"
   echo "请手动清理该目录或修改 sample_id，然后重试。"
   exit 1
fi

echo "步骤 1: 下载 Dorado 模型 ($decode_models_name)..."
$dorado_dir/dorado download --model ${decode_models_name}

echo "步骤 2: 开始 Basecalling..."
$dorado_dir/dorado basecaller \
    --device $dorado_run_device \
    --min-qscore $qual \
    --emit-fastq \
    --recursive \
    --verbose \
    ${decode_models_name} \
    "$raw_fast5_dir" | gzip -c > "${basecalled_fastq_dir}/${sample_id}.basecalled_reads.Q${qual}.pass.fastq.gz"

#######################################
# 结果检查
#######################################
if [ -f "${basecalled_fastq_dir}/${sample_id}.basecalled_reads.Q${qual}.pass.fastq.gz" ]; then
    echo ""
    echo "#########################################################################"
    echo " 成功！处理完成。"
    echo " 结果文件位于: ${basecalled_fastq_dir}/${sample_id}.basecalled_reads.Q${qual}.pass.fastq.gz"
    echo " 你可以将此文件用于后续的 NanoTrans 分析模块。"
    echo "#########################################################################"
else
    echo "错误: 未生成结果文件，请检查上方的报错信息。"
    exit 1
fi
