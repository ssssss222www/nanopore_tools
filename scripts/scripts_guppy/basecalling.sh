#!/bin/bash

# basecalling

/mnt/TWET-20250901A/ymm/guppy/ont-guppy/bin/guppy_basecaller \
   --input_path /mnt/TWET-20250901A/ymm/data/AT_vir/col0_4/fast5_multi \
   --save_path /mnt/TWET-20250901A/ymm/data/AT_vir/col0_4/fastq_new \
   --config rna_r9.4.1_70bps_hac.cfg \
   --recursive \
   --device 'cuda:0 cuda:1' \
   --num_callers 8 \
   --gpu_runners_per_device 2 \
   --chunks_per_runner 256
