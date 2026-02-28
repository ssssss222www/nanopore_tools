#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 6: 基因融合检测 (Module 06)
################################################################################
echo ">>> [Step 6] 运行 Module 06: Gene Fusion Detection..."
cd "$WORK_DIR/06.Gene_Fusion_Detection"

# JAFFAL 需要 java 等环境，已被 env.sh 加载
# 激活环境
source $miniconda3_dir/activate $build_dir/jaffal_conda_env

perl $NANOTRANS_HOME/scripts/batch_gene_fusion_detection.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -for_human no \
    -ref_dir $REF_DIR \
    -long_reads_dir $BASECALLED_FASTQ_DIR \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -batch $BATCH_ID \
    -debug no

source $miniconda3_dir/deactivate

# 绘图
source $miniconda3_dir/activate $build_dir/r_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_gene_fusion_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -gtf $REF_GENOME_GTF \
    -batch $BATCH_ID 
source $miniconda3_dir/deactivate

echo "Module 06 完成。"
