#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 4: RNA 修饰识别 (Module 04)
################################################################################
echo ">>> [Step 4] 运行 Module 04: RNA Modification..."
cd "$WORK_DIR/04.Isoform_RNA_Modification_Identification"

ISOFORM_CQ_DIR="$WORK_DIR/02.Isoform_Clustering_and_Quantification"

# 激活 xpore 环境
source $miniconda3_dir/activate $build_dir/xpore_conda_env

# 注意：Module 04 需要 long_reads_dir，这里假设是 raw fast5 或 fastq
# 实际上 NanoTrans 脚本这里使用的是 FASTQ 目录
perl $NANOTRANS_HOME/scripts/batch_rna_modification_detection.pl \
    -batch_id $BATCH_ID \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -long_reads_dir $BASECALLED_FASTQ_DIR \
    -isoform_cq_dir $ISOFORM_CQ_DIR \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -debug no

source $miniconda3_dir/deactivate

# 绘图
source $miniconda3_dir/activate $build_dir/r_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_rna_modification_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -batch $BATCH_ID \
    -top_n 20 \
    -debug no
source $miniconda3_dir/deactivate

echo "Module 04 完成。"
