#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 3: 差异表达分析 (Module 03)
################################################################################
echo ">>> [Step 3] 运行 Module 03: Differential Expression..."
cd "$WORK_DIR/03.Isoform_Expression_and_Splicing_Comparison"

ISOFORM_CQ_DIR="$WORK_DIR/02.Isoform_Clustering_and_Quantification"
QUANT_TABLE="${ISOFORM_CQ_DIR}/${BATCH_ID}/all_samples_combined/${BATCH_ID}.all_samples_combined.counts_matrix.tidy.txt"
RAW_QUANT_TABLE="${ISOFORM_CQ_DIR}/${BATCH_ID}/all_samples_combined/${BATCH_ID}.all_samples_combined.counts_matrix.tsv"
ISOFORM_BED="${ISOFORM_CQ_DIR}/${BATCH_ID}/all_samples_combined/${BATCH_ID}.all_samples_combined.flair_all_collapsed.isoforms.bed"
DIFFSPLICE_OUTDIR="./${BATCH_ID}/all_samples_combined/${BATCH_ID}_differential_splicing_output"

# 检查样本数，如果只有1个样本，跳过差异分析
SAMPLE_COUNT=$(tail -n +2 "$SAMPLE_TABLE_FILE" | wc -l)
if [ "$SAMPLE_COUNT" -lt 2 ]; then
    echo "警告: 样本表中只有 $SAMPLE_COUNT 个样本，无法进行差异表达分析。跳过 Module 03。"
else
    # 激活 R 环境 (尝试使用 flair_conda_env，因为没有 r_conda_env)
    source $miniconda3_dir/activate $build_dir/flair_conda_env
    
    # 1. 差异表达 (Gene/Isoform)
    Rscript --vanilla "$NANOTRANS_HOME/scripts/differential_expression.R" \
        --tidy_count_table "${QUANT_TABLE}" \
        --master_table "${SAMPLE_TABLE_FILE}" \
        --contrast "${CONTRAST}" \
        --batch_id "${BATCH_ID}" \
        --read_counts_cutoff 5

    # 2. 差异 Usage
    Rscript --vanilla "$NANOTRANS_HOME/scripts/differential_isoform_usage.R" \
        --tidy_count_table "${QUANT_TABLE}" \
        --master_table "${SAMPLE_TABLE_FILE}" \
        --contrast "${CONTRAST}" \
        --batch_id "${BATCH_ID}"
    
    source $miniconda3_dir/deactivate

    # 3. 差异剪接 (需要 Python 环境)
    source $miniconda3_dir/activate $build_dir/flair_conda_env
    
    mkdir -p "${DIFFSPLICE_OUTDIR}"
    call_ds_program=${build_dir}/flair_conda_env/lib/python*/site-packages/flair
    
    python ${call_ds_program}/call_diffsplice_events.py "${ISOFORM_BED}" "${DIFFSPLICE_OUTDIR}/diffsplice" "${RAW_QUANT_TABLE}"
    python ${call_ds_program}/es_as.py "${ISOFORM_BED}" > "${DIFFSPLICE_OUTDIR}/diffsplice.es.events.tsv"
    python ${call_ds_program}/es_as_inc_excl_to_counts.py "${RAW_QUANT_TABLE}" "${DIFFSPLICE_OUTDIR}/diffsplice.es.events.tsv" > "${DIFFSPLICE_OUTDIR}/diffsplice.es.events.quant.tsv"
    
    source $miniconda3_dir/deactivate
    
    # 统计差异剪接结果
    source $miniconda3_dir/activate $build_dir/flair_conda_env
    Rscript --vanilla "$NANOTRANS_HOME/scripts/differential_splicing.R" \
        --inputs_dir "${DIFFSPLICE_OUTDIR}" \
        --contrast "${CONTRAST}" \
        --threads "${THREADS}" \
        --batch_id "${BATCH_ID}"
    source $miniconda3_dir/deactivate
fi

echo "Module 03 完成。"
