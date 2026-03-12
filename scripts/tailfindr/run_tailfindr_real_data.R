#!/usr/bin/env Rscript

# Set library path to the conda environment
.libPaths(c(
  "/mnt/TenTC-0eec/micromamba/envs/tail/lib/R/library",
  "/home/user/R/x86_64-pc-linux-gnu-library/4.4"
))

# Load required libraries
library(tailfindr)
library(parallel)
library(dplyr)

# --- Configuration ---

# Base input directory
input_base_dir <- "/mnt/TWET-20250901A/ymm/rebasecalled"

# Output directory
output_base_dir <- "/mnt/TWET-20250901A/ymm/results/tailfindr/AT_vir"

# Sample information
# List of samples to process: name = relative path to fast5 files
samples <- list(
  "col0_1" = file.path(input_base_dir, "col0_1/workspace"),
  "col0_4" = file.path(input_base_dir, "col0_4/workspace"),
  "vir1_1" = file.path(input_base_dir, "vir1_1/workspace"),
  "vir1_4" = file.path(input_base_dir, "vir1_4/workspace")
)

# Number of cores to use
# Detect available cores, leave 2 free for system
num_cores <- 8
message("Using ", num_cores, " cores for processing.")

# Create output directory if it doesn't exist
if (!dir.exists(output_base_dir)) {
  message("Creating output directory: ", output_base_dir)
  dir.create(output_base_dir, recursive = TRUE)
}

# --- Processing Loop ---

for (sample_name in names(samples)) {
  fast5_dir <- samples[[sample_name]]
  
  message(paste0("\n", strrep("=", 50)))
  message(paste0("Processing Sample: ", sample_name))
  message(paste0("Input Directory: ", fast5_dir))
  message(paste0(strrep("=", 50), "\n"))
  
  # Check if input directory exists
  if (!dir.exists(fast5_dir)) {
    warning(paste("Input directory does not exist for sample:", sample_name, "- Skipping!"))
    next
  }
  
  # Create sample-specific output directory
  sample_output_dir <- file.path(output_base_dir, sample_name)
  if (!dir.exists(sample_output_dir)) {
    dir.create(sample_output_dir, recursive = TRUE)
  }
  
  # Output CSV filename
  csv_file <- paste0(sample_name, "_tails.csv")
  
  # Run tailfindr
  # We enable plotting as requested ("use all features")
  # Note: save_plots = TRUE might generate a large number of files if the dataset is huge.
  # We use rbokeh for interactive plots as per installation notes.
  
  tryCatch({
    df <- find_tails(
      fast5_dir = fast5_dir,
      save_dir = sample_output_dir,
      csv_filename = csv_file,
      num_cores = num_cores,
      basecall_group = 'Basecall_1D_001',
      save_plots = FALSE,           # 真实数据reads量大，开启会极大拖慢速度并占用大量磁盘
      plot_debug_traces = FALSE,   # Set to TRUE for more detailed debug plots if needed
      plotting_library = 'rbokeh'  # Use rbokeh for interactive plots
    )
    
    message(paste0("Successfully processed sample: ", sample_name))
    message(paste0("Results saved to: ", sample_output_dir))
    
    # Print a glimpse of the results
    if (!is.null(df)) {
      print(head(df))
    }
    
  }, error = function(e) {
    message(paste("Error processing sample:", sample_name))
    message(e)
  })
}

message("\nAll samples processed.")
