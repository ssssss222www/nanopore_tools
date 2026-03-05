#!/bin/bash

GTF=/media/user/Elements_YMM/Nanopore/data/reference/gtf/TAIR10.gtf
REF=/media/user/Elements_YMM/Nanopore/data/reference/total_ref.fa
BASE=/media/user/Elements_YMM/Nanopore/data/AT_vir

SAMPLES=(
    "control/col0_1/bam/col0-1.sort.bam control/col0_1/isoquant_output"
    "control/col0_4/bam/col0-4.sort.bam control/col0_4/isoquant_output"
    "treatment/vir1_1/bam/vir1-1.sort.bam treatment/vir1_1/isoquant_output"
    "treatment/vir1_4/bam/vir1-4.sort.bam treatment/vir1_4/isoquant_output"
)

for SAMPLE in "${SAMPLES[@]}"; do
    BAM=$(echo $SAMPLE | awk '{print $1}')
    OUT=$(echo $SAMPLE | awk '{print $2}')

    echo ">>> 正在处理: $BAM"

    isoquant.py \
        --gff $GTF \
        --reference $REF \
        --bam $BASE/$BAM \
        --data_type nanopore \
        --complete_genedb \
        --gene_quantification unique_only \
        --transcript_quantification unique_only \
        --splice_correction_strategy default_ont \
        --no_secondary \
        --threads 7 \
        -o $BASE/$OUT

    echo ">>> 完成: $OUT"
done

echo "全部样本处理完毕！"