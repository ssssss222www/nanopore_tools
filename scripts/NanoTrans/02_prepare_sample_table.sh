#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 0b: 准备样本表 (Master Sample Table)
################################################################################
echo ">>> [Step 0b] 准备样本表..."
cd "$WORK_DIR"

if [ -n "$EXISTING_SAMPLE_TABLE" ] && [ -f "$EXISTING_SAMPLE_TABLE" ]; then
    cp "$EXISTING_SAMPLE_TABLE" "$SAMPLE_TABLE_FILE"
    echo "使用已存在的样本表: $SAMPLE_TABLE_FILE"
else
    if [ ! -f "$SAMPLE_TABLE_FILE" ]; then
        echo "生成示例样本表..."
        # 自动搜索 FASTQ 文件生成表格 (仅作为示例，可能需要手动调整)
        echo -e "sample_id\tcomparison_group\treplicate_id\tbasecalled_fastq_file\tbasecalled_fast5_dir\tnote" > "$SAMPLE_TABLE_FILE"
        
        # 假设只有一个样本，尝试找到 fastq 文件
        FASTQ_FILE=$(find "$BASECALLED_FASTQ_DIR" -name "*.fastq.gz" | head -n 1)
        if [ -z "$FASTQ_FILE" ]; then
             FASTQ_FILE="path/to/your/sample.fastq.gz"
        fi
        
        # 写入一行示例数据
        echo -e "Sample1\ttreated\trep1\t${FASTQ_FILE}\t${RAW_FAST5_DIR}\tDemo_Sample" >> "$SAMPLE_TABLE_FILE"
        
        echo "警告: 已生成默认样本表 $SAMPLE_TABLE_FILE"
        echo "请务必检查该文件内容是否正确！(特别是 comparison_group 和 文件路径)"
    else
        echo "样本表已存在: $SAMPLE_TABLE_FILE"
    fi
fi

echo "Step 0b 完成。"
