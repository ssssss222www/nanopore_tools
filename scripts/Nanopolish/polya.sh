#!/bin/bash

# 创建输出目录
mkdir -p /media/user/Elements_YMM/Nanopore/data/AT_202601/polya

echo "Step 1: Merging fastq files..."
cat /media/user/Elements_YMM/Nanopore/data/AT_202601/fastq/pass/*.fastq > \
    /media/user/Elements_YMM/Nanopore/data/AT_202601/fastq/AT_202601_all.fastq

echo "Step 2: Merging BAM files..."
samtools merge \
  /media/user/Elements_YMM/Nanopore/data/AT_202601/bam/AT_202601_merged.bam \
  /media/user/Elements_YMM/Nanopore/data/AT_202601/bam/*.bam

echo "Step 3: Indexing merged BAM..."
samtools index /media/user/Elements_YMM/Nanopore/data/AT_202601/bam/AT_202601_merged.bam

echo "Step 4: Building nanopolish index..."
nanopolish index \
  --directory=/media/user/Elements_YMM/Nanopore/data/AT_202601/fast5/pass \
  /media/user/Elements_YMM/Nanopore/data/AT_202601/fastq/AT_202601_all.fastq

echo "Step 5: Running polyA analysis..."
nanopolish polya \
  --threads=8 \
  --reads=/media/user/Elements_YMM/Nanopore/data/AT_202601/fastq/AT_202601_all.fastq \
  --bam=/media/user/Elements_YMM/Nanopore/data/AT_202601/bam/AT_202601_merged.bam \
  --genome=/media/user/Elements_YMM/Nanopore/data/AT_202601/reference/total_ref.fa \
  > /media/user/Elements_YMM/Nanopore/data/AT_202601/polya/polya_results.tsv

echo "Done! Results saved to polya_results.tsv"
