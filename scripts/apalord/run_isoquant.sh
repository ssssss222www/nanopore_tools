#!/bin/bash
source $(micromamba shell hook --shell bash)
micromamba activate /mnt/TenTC-0eec/micromamba/envs/isoquant

GTF=/media/user/Elements_YMM/Nanopore/data/reference/gtf/TAIR10.gtf
REF=/media/user/Elements_YMM/Nanopore/data/reference/total_ref.fa
BASE_IN=/media/user/Elements_YMM/Nanopore/data/AT_vir
BASE_OUT=/mnt/TWET-20250901A/ymm/results/apalord/isoquant

mkdir -p $BASE_OUT

SAMPLES=(
    "control/col0_1/bam/col0-1.sort.bam col0_1"
    "control/col0_4/bam/col0-4.sort.bam col0_4"
    "treatment/vir1_1/bam/vir1-1.sort.bam vir1_1"
    "treatment/vir1_4/bam/vir1-4.sort.bam vir1_4"
)

for SAMPLE in "${SAMPLES[@]}"; do
    BAM=$(echo $SAMPLE | awk '{print $1}')
    OUT=$(echo $SAMPLE | awk '{print $2}')

    echo ">>> 正在处理: $BAM"

    isoquant.py \
        --genedb $GTF \
        --reference $REF \
        --bam $BASE_IN/$BAM \
        --data_type nanopore \
        --complete_genedb \
        --gene_quantification unique_only \
        --transcript_quantification unique_only \
        --splice_correction_strategy default_ont \
        --large_output read_assignments corrected_bed \
        --no_gzip \
        --threads 7 \
        -o $BASE_OUT/$OUT

    echo ">>> 完成: $OUT"
done

echo "全部样本处理完毕！"