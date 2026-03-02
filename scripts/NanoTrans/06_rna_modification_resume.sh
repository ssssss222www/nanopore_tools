#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

echo ">>> [Resume] Resuming Step 4: RNA Modification from post-loop stage..."

# Define directories
STEP4_DIR="$WORK_DIR/04.Isoform_RNA_Modification_Identification"
BATCH_DIR="$STEP4_DIR/$BATCH_ID"
COMBINED_DIR="$BATCH_DIR/all_samples_combined"

# Check if directories exist
if [ ! -d "$BATCH_DIR" ]; then
    echo "Error: Batch directory $BATCH_DIR does not exist. Cannot resume."
    exit 1
fi

# Create combined output directory if it doesn't exist
mkdir -p "$COMBINED_DIR"

# Change to batch directory
cd "$BATCH_DIR"

# 激活 xpore 环境
echo ">>> Activating xpore environment..."
source $miniconda3_dir/activate $build_dir/xpore_conda_env

# Run xpore diffmod
echo ">>> Running xpore diffmod..."
# Check if experimental design file exists
if [ ! -f "$BATCH_ID.experimental_design.yml" ]; then
    echo "Error: $BATCH_ID.experimental_design.yml not found in $BATCH_DIR"
    exit 1
fi

# Fix YAML format for xpore (ensure replicate IDs are strings)
echo ">>> Fixing YAML format in $BATCH_ID.experimental_design.yml..."
sed -i 's/^    \([0-9]\+\):/    "\1":/' "$BATCH_ID.experimental_design.yml"

$xpore_dir/xpore diffmod --n_processes $THREADS --config "$BATCH_ID.experimental_design.yml"

# Run xpore postprocessing
echo ">>> Running xpore postprocessing..."
$xpore_dir/xpore postprocessing --diffmod_dir "$COMBINED_DIR"

# Run tidy scripts
echo ">>> Running tidy scripts..."
TRANSCRIPT2GENE_MAP_PATH="$WORK_DIR/00.Reference_Genome/ref.transcript2gene_map.txt"

perl $NANOTRANS_HOME/scripts/tidy_xpore_output.pl \
    -i "$COMBINED_DIR/diffmod.table" \
    -o "$COMBINED_DIR/$BATCH_ID.rna_modification.diffmod.table.tidy.txt" \
    -x "$TRANSCRIPT2GENE_MAP_PATH"

perl $NANOTRANS_HOME/scripts/tidy_xpore_output.pl \
    -i "$COMBINED_DIR/majority_direction_kmer_diffmod.table" \
    -o "$COMBINED_DIR/$BATCH_ID.rna_modification.majority_direction_kmer_diffmod.table.tidy.txt" \
    -x "$TRANSCRIPT2GENE_MAP_PATH"

source $miniconda3_dir/deactivate

# 绘图 (Running plotting)
echo ">>> Running plotting..."
# Use flair_conda_env instead of r_conda_env as it contains R and necessary libraries
source $miniconda3_dir/activate $build_dir/flair_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_rna_modification_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -batch $BATCH_ID \
    -top_n 20 \
    -debug no

source $miniconda3_dir/deactivate

echo ">>> Resume completed successfully."
