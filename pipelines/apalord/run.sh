#!/bin/bash

# isoquant
micromamba activate /mnt/TenTC-0eec/micromamba/envs/isoquant
bash /mnt/TWET-20250901A/ymm/scripts/apalord/run_isoquant.sh

# apalord
micromamba activate /mnt/TenTC-0eec/micromamba/envs/apalord
bash /mnt/TWET-20250901A/ymm/scripts/apalord/run_apalord_real.sh