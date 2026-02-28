#!/bin/bash
## convert single-fast5 to multi-fast5
single_to_multi_fast5 \
    --input_path /media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/fast5/pass/ \
    --save_path /media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/fast5_multi/ \
    --recursive \
    --threads 4