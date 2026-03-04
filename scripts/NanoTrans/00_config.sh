#!/bin/bash
set -e -o pipefail

################################################################################
# 用户配置区 (请根据实际情况修改以下变量)
################################################################################

# 1. 项目基础设置
# 脚本所在目录
SCRIPT_DIR="/mnt/TWET-20250901A/ymm/scripts/NanoTrans"

# NanoTrans 根目录
export NANOTRANS_HOME="/mnt/TWET-20250901A/ymm/nanoTrans"

# 工作/输出目录 (所有结果将生成在这里)
export WORK_DIR="/media/user/Elements_YMM/Nanopore/results/nanotrans"

# 2. 数据路径设置
# 批次ID (用于输出目录命名)
# 注意：BATCH_ID 中不能包含下划线 "_", 否则会导致 flair quantify 报错
# 原 ID: AT_vir_analysis
export BATCH_ID="ATvirAnalysis"

# [单样本模式配置 - 已注释]
# export BATCH_ID="Arabidopsis_vir1_1"
# export RAW_FAST5_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/fast5_multi"
# export BASECALLED_FASTQ_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/merge_fastq"

# [多样本模式配置]
# 为了兼容部分脚本对这两个变量的引用，这里设置为第一个样本的路径或者空值
# 注意：实际运行中应优先读取 Master Sample Table 中的路径
export RAW_FAST5_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir/control/col0_1/fast5_multi"
export BASECALLED_FASTQ_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir/control/col0_1/merge_fastq"

# 3. 参考基因组设置
# 参考基因组 FASTA 文件路径
export REF_FASTA="/mnt/TWET-20250901A/ymm/data/AT_vir/reference/total_ref.fa"
# 参考基因组 GTF 文件路径
export REF_GTF="/mnt/TWET-20250901A/ymm/data/AT_vir/reference/gtf/TAIR10.gtf"

# 4. 样本信息表设置 (Master Sample Table)
# 如果你已经有了样本表，请设置路径；否则留空，脚本将尝试为你生成一个单样本的示例表
# 如果 /media/user/Elements_YMM/Nanopore/results/nanotrans/Master_Sample_Table.txt 已经存在
export EXISTING_SAMPLE_TABLE="$SCRIPT_DIR/Master_Sample_Table.txt"

# 5. 实验设计 (用于差异表达分析)
# 对比组设置 (格式: 实验组,对照组)。如果是单样本，模块03将无法正常运行差异分析。
export CONTRAST="treated,control" 
# 线程数
export THREADS=6

################################################################################
# 初始化环境
################################################################################

echo ">>> 加载 NanoTrans 环境..."
if [ -f "$NANOTRANS_HOME/env.sh" ]; then
    source "$NANOTRANS_HOME/env.sh"
else
    echo "Error: 找不到 env.sh，请先运行 install_dependencies.sh！"
    echo "Expected path: $NANOTRANS_HOME/env.sh"
    exit 1
fi

# 创建工作目录
mkdir -p "$WORK_DIR"

# 创建标准目录结构
mkdir -p "$WORK_DIR/00.Reference_Genome"
mkdir -p "$WORK_DIR/00.Long_Reads"
mkdir -p "$WORK_DIR/01.Reference_Genome_based_Read_Mapping"
mkdir -p "$WORK_DIR/02.Isoform_Clustering_and_Quantification"
mkdir -p "$WORK_DIR/03.Isoform_Expression_and_Splicing_Comparison"
mkdir -p "$WORK_DIR/04.Isoform_RNA_Modification_Identification"
mkdir -p "$WORK_DIR/05.Isoform_PolyA_Tail_Length_Profiling"
mkdir -p "$WORK_DIR/06.Gene_Fusion_Detection"
mkdir -p "$WORK_DIR/07.Report"

# 导出一些常用的变量
export TRANSCRIPT2GENE_MAP="$WORK_DIR/00.Reference_Genome/ref.transcript2gene_map.txt"
export REF_GENOME_GTF="$WORK_DIR/00.Reference_Genome/ref.genome.gtf"
export REF_DIR="$WORK_DIR/00.Reference_Genome"
export SAMPLE_TABLE_FILE="$SCRIPT_DIR/Master_Sample_Table_fixed.txt"

echo "配置已加载，工作目录: $WORK_DIR"
