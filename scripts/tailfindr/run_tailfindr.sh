#!/bin/bash

# Script to run tailfindr on real DRS data
# Environment: /mnt/TenTC-0eec/micromamba/envs/tail
# R Script: /mnt/TWET-20250901A/ymm/scripts/tailfindr/run_tailfindr_real_data.R

echo "Starting tailfindr analysis..."
echo "Date: $(date)"

# Use micromamba run to execute the R script within the environment
micromamba run -p /mnt/TenTC-0eec/micromamba/envs/tail \
  Rscript /mnt/TWET-20250901A/ymm/scripts/tailfindr/run_tailfindr_real_data.R

echo "Analysis complete."
echo "Date: $(date)"
