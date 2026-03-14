#!/bin/bash

# Exit on error
set -e

# Activate environment
# Note: We assume micromamba is available. If not, you might need to adjust the path.
# Trying to initialize micromamba shell hook
if command -v micromamba &> /dev/null; then
    eval "$(micromamba shell hook --shell bash)"
    micromamba activate /mnt/TenTC-0eec/micromamba/envs/lapa
else
    echo "micromamba command not found. Please ensure it is in your PATH."
    echo "Trying to activate assuming conda-style..."
    source activate /mnt/TenTC-0eec/micromamba/envs/lapa || true
fi

# Directories
DATA_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir"
REF_DIR="/mnt/TWET-20250901A/ymm/data/AT_vir/reference"
OUT_DIR="/mnt/TWET-20250901A/ymm/results/lapa"
SCRIPT_DIR="/mnt/TWET-20250901A/ymm/scripts/lapa"

# Ensure directories exist
mkdir -p "$OUT_DIR"
mkdir -p "$SCRIPT_DIR"

# Reference files
FASTA="$REF_DIR/total_ref.fa"
GTF="$REF_DIR/gtf/TAIR10.gtf"
CHROM_SIZES="$REF_DIR/chrom_sizes"

# Check FASTA index and generate chrom_sizes
if [ ! -f "$FASTA.fai" ]; then
    echo "Error: Fasta index $FASTA.fai not found."
    exit 1
fi

if [ ! -f "$CHROM_SIZES" ]; then
    echo "Generating chrom_sizes from fai..."
    awk '{print $1 "\t" $2}' "$FASTA.fai" > "$CHROM_SIZES"
fi

# Create samples.csv
SAMPLES_CSV="$SCRIPT_DIR/samples.csv"
echo "sample,dataset,path" > "$SAMPLES_CSV"

# Add samples
# We explicitly map the known file paths to ensure correctness
echo "col0_1,control,$DATA_DIR/control/col0_1/bam/col0-1.sort.bam" >> "$SAMPLES_CSV"
echo "col0_4,control,$DATA_DIR/control/col0_4/bam/col0-4.sort.bam" >> "$SAMPLES_CSV"
echo "vir1_1,treatment,$DATA_DIR/treatment/vir1_1/bam/vir1-1.sort.bam" >> "$SAMPLES_CSV"
echo "vir1_4,treatment,$DATA_DIR/treatment/vir1_4/bam/vir1-4.sort.bam" >> "$SAMPLES_CSV"

echo "Created samples config at $SAMPLES_CSV"
cat "$SAMPLES_CSV"

# Run LAPA
echo "Starting LAPA analysis..."
# method='end' is recommended for Nanopore data to use alignment ends directly
lapa --alignment "$SAMPLES_CSV" \
     --fasta "$FASTA" \
     --annotation "$GTF" \
     --chrom_sizes "$CHROM_SIZES" \
     --output_dir "$OUT_DIR" \
     --counting_method end

echo "LAPA analysis completed. Results are in $OUT_DIR"
