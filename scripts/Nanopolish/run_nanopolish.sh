#!/bin/bash
# ============================================================
# Nanopolish polyA Batch Analysis — AT_vir dataset
# 数据结构:
#   AT_vir/
#     control/col0_1/, col0_4/
#     treatment/vir1_1/, vir1_4/
#   每个样本目录下含: bam/, fast5_multi/, merge_fastq/
# ============================================================

set -euo pipefail

# ── 全局路径配置 ────────────────────────────────────────────
BASE_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir"
REFERENCE="/media/user/Elements_YMM/Nanopore/data/reference/fa/TAIR10.fa"   # ← 按实际路径修改
OUTPUT_BASE="/media/user/Elements_YMM/Nanopore/results/nanopolish"
THREADS=8
NANOPOLISH="/mnt/TWET-20250901A/ymm/nanopolish/nanopolish"

# ── 样本列表（组别:样本名） ──────────────────────────────────
declare -A SAMPLES=(
    [control]="col0_1 col0_4"
    [treatment]="vir1_1 vir1_4"
)

# ── 日志函数 ─────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
die() { echo "[ERROR] $*" >&2; exit 1; }

mkdir -p "$OUTPUT_BASE"
log "Output directory: $OUTPUT_BASE"

# ── 主循环 ───────────────────────────────────────────────────
for GROUP in "${!SAMPLES[@]}"; do
    for SAMPLE in ${SAMPLES[$GROUP]}; do

        SAMPLE_DIR="${BASE_DIR}/${GROUP}/${SAMPLE}"
        FAST5_DIR="${SAMPLE_DIR}/fast5_multi"
        FASTQ_DIR="${SAMPLE_DIR}/merge_fastq"
        BAM_DIR="${SAMPLE_DIR}/bam"
        OUT_DIR="${OUTPUT_BASE}/${SAMPLE}"

        log "=============================="
        log "Processing: ${GROUP}/${SAMPLE}"
        log "=============================="

        # ── 路径检查 ────────────────────────────────────────
        [[ -d "$FAST5_DIR"  ]] || die "fast5_multi not found: $FAST5_DIR"
        [[ -d "$FASTQ_DIR"  ]] || die "merge_fastq not found: $FASTQ_DIR"
        [[ -d "$BAM_DIR"    ]] || die "bam dir not found: $BAM_DIR"
        [[ -f "$REFERENCE"  ]] || die "Reference not found: $REFERENCE"

        mkdir -p "$OUT_DIR"

        # ── Step 1: 定位 fastq.gz（已合并，直接使用） ────────
        # merge_fastq 中已有合并好的 .fastq.gz，直接使用，无需再合并
        MERGED_FASTQ=$(find "$FASTQ_DIR" -maxdepth 1 -name "*.fastq.gz" | grep -v '\.index' | head -1)
        [[ -n "$MERGED_FASTQ" ]] || die "No .fastq.gz found in $FASTQ_DIR"
        log "[${SAMPLE}] Step 1: Using existing fastq.gz: $MERGED_FASTQ"

        # ── Step 2: 准备 BAM（使用已有的 sort.bam） ─────────
        # 自动寻找 *.sort.bam，如有多个则先合并
        SORTED_BAMS=( "${BAM_DIR}"/*.sort.bam )
        FINAL_BAM="${OUT_DIR}/${SAMPLE}.bam"

        if [[ ! -f "$FINAL_BAM" ]]; then
            log "[${SAMPLE}] Step 2: Preparing BAM..."
            if [[ ${#SORTED_BAMS[@]} -eq 1 ]]; then
                cp "${SORTED_BAMS[0]}" "$FINAL_BAM"
            else
                samtools merge -f "$FINAL_BAM" "${SORTED_BAMS[@]}" \
                    || die "samtools merge failed for $SAMPLE"
            fi
            samtools index "$FINAL_BAM" \
                || die "samtools index failed for $SAMPLE"
        else
            log "[${SAMPLE}] Step 2: BAM already exists, skipping."
        fi

        # ── Step 3: Nanopolish index ─────────────────────────
        # 检测 .index.readdb（最关键的索引文件），已存在则跳过
        INDEX_FILE="${MERGED_FASTQ}.index.readdb"
        if [[ ! -f "$INDEX_FILE" ]]; then
            log "[${SAMPLE}] Step 3: Building nanopolish index..."
            $NANOPOLISH index \
                --directory="$FAST5_DIR" \
                "$MERGED_FASTQ" \
                || die "nanopolish index failed for $SAMPLE"
        else
            log "[${SAMPLE}] Step 3: Index (.index.readdb) already exists, skipping."
        fi

        # ── Step 4: Nanopolish polya ─────────────────────────
        POLYA_OUT="${OUT_DIR}/${SAMPLE}_polya.tsv"
        if [[ ! -f "$POLYA_OUT" ]]; then
            log "[${SAMPLE}] Step 4: Running nanopolish polya..."
            $NANOPOLISH polya \
                --threads="$THREADS" \
                --reads="$MERGED_FASTQ" \
                --bam="$FINAL_BAM" \
                --genome="$REFERENCE" \
                > "$POLYA_OUT" \
                || die "nanopolish polya failed for $SAMPLE"
        else
            log "[${SAMPLE}] Step 4: polyA result already exists, skipping."
        fi

        log "[${SAMPLE}] Done → $POLYA_OUT"

    done
done

log "=============================="
log "All samples complete!"
log "Results saved to:"
for GROUP in "${!SAMPLES[@]}"; do
    for SAMPLE in ${SAMPLES[$GROUP]}; do
        log "  ${OUTPUT_BASE}/${SAMPLE}/${SAMPLE}_polya.tsv"
    done
done
log "=============================="