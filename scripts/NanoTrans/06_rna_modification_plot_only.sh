#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

echo ">>> [Plotting] Running only plotting step..."

# Define directories
STEP4_DIR="$WORK_DIR/04.Isoform_RNA_Modification_Identification"
BATCH_DIR="$STEP4_DIR/$BATCH_ID"

# Change to step 4 directory (parent of batch directory)
cd "$STEP4_DIR"

# 绘图 (Running plotting)
echo ">>> Running plotting..."
source $miniconda3_dir/activate $build_dir/flair_conda_env

# Check if Rscript is available
if ! command -v Rscript &> /dev/null; then
    echo "Error: Rscript could not be found in current environment."
    exit 1
fi

perl $NANOTRANS_HOME/scripts/batch_plot_rna_modification_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -batch $BATCH_ID \
    -top_n 20 \
    -debug no

source $miniconda3_dir/deactivate

echo ">>> Plotting completed successfully."
