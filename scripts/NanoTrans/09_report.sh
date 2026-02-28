#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 7: 生成报告 (Module 07)
################################################################################
echo ">>> [Step 7] 生成 HTML 报告..."
cd "$WORK_DIR/07.Report"

# 复制报告模板
cp $NANOTRANS_HOME/Project_Template/07.Report/NanoTrans_Report.qmd .

# 激活 Quarto 环境
source $miniconda3_dir/activate $build_dir/quarto_conda_env

# 确保 R 在 PATH 中
R_DIR=$(which R)
R_DIR=${R_DIR%/*}
export PATH=${R_DIR}:$PATH
export R_LIBS=$NANOTRANS_HOME/build/R_libs

quarto render NanoTrans_Report.qmd -P "wkdir:../" -P "dataset:${BATCH_ID}" --output NanoTrans_Report_${BATCH_ID}.html

source $miniconda3_dir/deactivate

echo "==========================================================="
echo "所有分析已完成！"
echo "最终报告位置: $WORK_DIR/07.Report/NanoTrans_Report_${BATCH_ID}.html"
echo "==========================================================="
