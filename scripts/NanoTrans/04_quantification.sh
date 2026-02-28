#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 2: 定量 (Module 02)
################################################################################
echo ">>> [Step 2] 运行 Module 02: Isoform Quantification..."
cd "$WORK_DIR/02.Isoform_Clustering_and_Quantification"

MAPPING_DIR="$WORK_DIR/01.Reference_Genome_based_Read_Mapping"

# 激活 flair 环境
source $miniconda3_dir/activate $build_dir/flair_conda_env

perl $NANOTRANS_HOME/scripts/batch_isoform_clustering_and_quantification.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -ref_dir $REF_DIR \
    -mapping_dir $MAPPING_DIR \
    -long_reads_dir $WORK_DIR/00.Long_Reads \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -batch $BATCH_ID \
    -debug no

# 绘图
# source $miniconda3_dir/activate $build_dir/r_conda_env
# perl $NANOTRANS_HOME/scripts/batch_plot_isoform_usage_for_pdf.pl \
#    -sample_table $SAMPLE_TABLE_FILE \
#    -batch $BATCH_ID \
#    -debug no
# source $miniconda3_dir/deactivate

echo "Module 02 完成。"
