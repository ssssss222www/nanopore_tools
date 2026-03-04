#!/bin/bash

## basecalling
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/custom_data_preprocessing_guppy.sh

## prepare genome
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/01_prepare_genome.sh

## prepare sample table
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/02_prepare_sample_table.sh

## mapping
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/03_mapping.sh

## quality filtering
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/04_quality_filtering.sh

## differential expression
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/05_differential_expression.sh

## rna_modification
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/06_rna_modification.sh

## polya_profiling
bash /mnt/TWET-20250901A/ymm/scripts/NanoTrans/07_polya_profiling.sh