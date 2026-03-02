#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 5: PolyA 尾长分析 (Module 05)
################################################################################
echo ">>> [Step 5] 运行 Module 05: PolyA Profiling..."
cd "$WORK_DIR/05.Isoform_PolyA_Tail_Length_Profiling"

ISOFORM_CQ_DIR="$WORK_DIR/02.Isoform_Clustering_and_Quantification"
MAPPING_DIR="$WORK_DIR/01.Reference_Genome_based_Read_Mapping"

# 激活环境 (通常使用 nanopolish)
# 使用 flair_conda_env 代替 nanopolish_conda_env，因为它包含 nanopolish 以及 R 和 ggplot2 等依赖
source $miniconda3_dir/activate $build_dir/flair_conda_env

# 注意：Raw fast5 目录需要传递给脚本
# 这里的 long_reads_dir 在 Module 05 中实际上是指包含 fast5 的目录，或者是 fastq 目录但能找到 fast5
# 原始脚本参数 -long_reads_dir 指向的是 FASTQ 目录，但是 sample_table 中有 fast5 路径
perl $NANOTRANS_HOME/scripts/batch_polya_tail_length_profiling.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -long_reads_dir $WORK_DIR/00.Long_Reads \
    -isoform_cq_dir $ISOFORM_CQ_DIR \
    -method nanopolish \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -batch $BATCH_ID \
    -debug no

source $miniconda3_dir/deactivate

# 绘图
# source $miniconda3_dir/activate $build_dir/r_conda_env
# perl $NANOTRANS_HOME/scripts/batch_plot_polya_tail_length_results.pl \
#    -sample_table $SAMPLE_TABLE_FILE \
#    -threads $THREADS \
#    -batch $BATCH_ID \
#    -debug no
# source $miniconda3_dir/deactivate

echo "Module 05 完成。"
