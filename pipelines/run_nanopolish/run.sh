#!/bin/bash
## convert single-fast5 to multi-fast5
bash /mnt/TWET-20250901A/YMM/scripts/guppy/convet_multi.sh

## bascalling
bash /mnt/TWET-20250901A/YMM/scripts/guppy/basecalling.sh

## mapping
bash /mnt/TWET-20250901A/ymm/scripts/Nanopolish/mapping.sh

## polya_analysis
bash /mnt/TWET-20250901A/ymm/scripts/Nanopolish/run_nanopolish.sh
