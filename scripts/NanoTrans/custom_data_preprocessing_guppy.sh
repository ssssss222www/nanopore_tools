#!/bin/bash
set -e -o pipefail

#######################################
# 1. 基础配置 (根据实际情况修改这部分)
#######################################

# [重要] 原始 fast5 文件所在的目录 (请使用绝对路径)
raw_fast5_dir="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_4/fast5_multi" 

# [重要] 样本名
sample_id="Arabidopsis_vir1_4"

# [重要] 测序芯片版本
flowcell_version="FLO-MIN106"

# [重要] 测序试剂盒版本
sequencing_kit_version="SQK-RNA001"

# [可选] 运行模式: "cpu" (慢) 或 "gpu" (需要 NVIDIA 显卡环境)
guppy_run_mode="gpu"

# [可选] 线程数
threads=8

#######################################
# 加载环境 (自动寻找项目根目录的 env.sh)
#######################################
ENV_FILE="/mnt/TWET-20250901A/ymm/nanoTrans/env.sh"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Error: 找不到 env.sh 文件: $ENV_FILE"
    exit 1
fi

#######################################
# 高级配置 (通常不需要修改)
#######################################
# 输出目录
basecalled_fast5_dir="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_4/fastq_new"
basecalled_fastq_dir="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_4/merge_fastq"

# Guppy 参数
qual=5
trim_strategy="rna" 
u_substitution="false"
reverse_sequence="true"
num_callers_in_cpu_mode=$threads
gpu_device="cuda:2,3"
num_callers_in_gpu_mode=16
gpu_runners_per_device=6

# GPU 环境路径 (仅当 guppy_run_mode="gpu" 时生效)
gpu_bin_path="/public/software/cuda-11.4/bin"
gpu_lib_path="/public/software/cuda-11.4/lib64"

#######################################
# 开始处理
#######################################

echo "=========================================="
echo " 正在处理样本: $sample_id (使用 Guppy)"
echo " 输入目录: $raw_fast5_dir"
echo " Flowcell: $flowcell_version"
echo " Kit: $sequencing_kit_version"
echo " 模式: $guppy_run_mode"
echo "=========================================="

# 检查输入
if [ ! -d "$raw_fast5_dir" ]; then
    echo "错误: 找不到输入目录 $raw_fast5_dir"
    exit 1
fi

mkdir -p "$basecalled_fast5_dir"
mkdir -p "$basecalled_fastq_dir"

# GPU 环境配置
if [[ $guppy_run_mode == "gpu" ]]; then
    export PATH=$gpu_bin_path:$PATH
    export LD_LIBRARY_PATH=$gpu_lib_path:$LD_LIBRARY_PATH
fi

echo "步骤 1: 开始 Basecalling..."

if [[ "$guppy_run_mode" == "gpu" ]]; then
    $guppy_gpu_dir/guppy_basecaller \
    --flowcell $flowcell_version \
    --kit $sequencing_kit_version \
    --recursive \
    --trim_strategy $trim_strategy \
    --input_path "$raw_fast5_dir" \
    --save_path "$basecalled_fast5_dir" \
    # --fast5_out \
    --min_qscore $qual \
    --device $gpu_device \
    --num_callers $num_callers_in_gpu_mode \
    --gpu_runners_per_device $gpu_runners_per_device \
    --u_substitution $u_substitution \
    --reverse_sequence $reverse_sequence \
    --compress_fastq
else
    $guppy_cpu_dir/guppy_basecaller \
    --flowcell $flowcell_version \
    --kit $sequencing_kit_version \
    --recursive \
    --trim_strategy $trim_strategy \
    --input_path "$raw_fast5_dir" \
    --save_path "$basecalled_fast5_dir" \
    --fast5_out \
    --min_qscore $qual \
    --num_callers $num_callers_in_cpu_mode \
    --cpu_threads_per_caller 1 \
    --u_substitution $u_substitution \
    --reverse_sequence $reverse_sequence \
    --compress_fastq
fi

echo "步骤 2: 合并 FASTQ 文件..."
# 合并 pass 目录下的所有 fastq
cat "$basecalled_fast5_dir/pass/"*.fastq.gz > "$basecalled_fastq_dir/$sample_id.basecalled_reads.Q${qual}.pass.fastq.gz"

#######################################
# 结果检查
#######################################
if [ -f "$basecalled_fastq_dir/$sample_id.basecalled_reads.Q${qual}.pass.fastq.gz" ]; then
    echo ""
    echo "#########################################################################"
    echo " 成功！Guppy Basecalling 完成。"
    echo " 结果文件: $basecalled_fastq_dir/$sample_id.basecalled_reads.Q${qual}.pass.fastq.gz"
    echo "#########################################################################"
else
    echo "错误: 未生成结果文件，请检查上方的报错信息。"
    exit 1
fi
