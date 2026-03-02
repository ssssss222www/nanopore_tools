#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 7: 生成报告 (Module 07)
################################################################################
# 复制报告模板
# 由于权限问题，我们先手动复制到 tmp，然后再尝试（虽然脚本中可能无法复制到 /media）
# 但我们可以尝试直接使用源文件，或者假设文件已经存在
# 更好的方法是直接指向模板文件，但 quarto render 可能需要在当前目录有 qmd
# 让我们尝试在 /tmp 下运行 quarto，然后把结果移动回来？
# 或者我们修改脚本，不执行 cp，而是直接使用绝对路径渲染（如果 quarto 支持）
# 但 qmd 通常依赖相对路径。

# 既然直接 cp 失败，我们可以尝试让用户手动 cp，或者跳过 cp 步骤（假设用户已经 cp 了）
# 但为了自动化，我们尝试在 /tmp 工作
echo ">>> Working in temporary directory for report generation..."
TMP_REPORT_DIR="/tmp/NanoTrans_Report_${BATCH_ID}"
mkdir -p "$TMP_REPORT_DIR"
cd "$TMP_REPORT_DIR"
cp "$NANOTRANS_HOME/Project_Template/07.Report/NanoTrans_Report.qmd" .

# 激活 Quarto 环境
# 使用 flair_conda_env，因为它包含 R 和必要的依赖
source $miniconda3_dir/activate $build_dir/flair_conda_env

# 确保 R 在 PATH 中
R_DIR=$(which R)
R_DIR=${R_DIR%/*}
export PATH=${R_DIR}:$PATH
# 确保 R_LIBS 包含所需的库路径
export R_LIBS="$NANOTRANS_HOME/build/R_libs:$NANOTRANS_HOME/build/flair_conda_env/lib/R/library"

# 确保 quarto 在 PATH 中
export PATH="$NANOTRANS_HOME/build/quarto_conda_env/bin:$PATH"

# 渲染报告
# wkdir 指向项目工作目录，dataset 指向 BATCH_ID
quarto render NanoTrans_Report.qmd -P "wkdir:$WORK_DIR" -P "dataset:${BATCH_ID}" --output "NanoTrans_Report_${BATCH_ID}.html"

# 将结果移动回目标目录
# 由于 cp 可能失败，我们只打印位置
echo ">>> Report generated in $TMP_REPORT_DIR/NanoTrans_Report_${BATCH_ID}.html"
echo ">>> Please manually copy it to $WORK_DIR/07.Report/ if needed."

# 尝试移动（如果可能）
if cp "NanoTrans_Report_${BATCH_ID}.html" "$WORK_DIR/07.Report/"; then
    echo ">>> Successfully copied report to $WORK_DIR/07.Report/"
else
    echo ">>> Failed to copy report to $WORK_DIR/07.Report/. It remains in $TMP_REPORT_DIR"
fi

source $miniconda3_dir/deactivate

echo "==========================================================="
echo "所有分析已完成！"
echo "最终报告位置: $WORK_DIR/07.Report/NanoTrans_Report_${BATCH_ID}.html"
echo "==========================================================="
