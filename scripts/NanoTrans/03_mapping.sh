#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 1: 比对 (Module 01)
################################################################################
echo ">>> [Step 1] 运行 Module 01: Read Mapping..."
cd "$WORK_DIR/01.Reference_Genome_based_Read_Mapping"

perl $NANOTRANS_HOME/scripts/batch_long_read_spliced_mapping.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -ref_dir $REF_DIR \
    -long_reads_dir $WORK_DIR/00.Long_Reads \
    -batch $BATCH_ID \
    -debug no

echo "Module 01 完成。"
