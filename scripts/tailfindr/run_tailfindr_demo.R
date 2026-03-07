.libPaths("/mnt/TenTC-0eec/micromamba/envs/tail/lib/R/library")

library(tailfindr)
library(parallel)

# Define output directory
output_dir <- "/mnt/TWET-20250901A/ymm/results/tailfindr"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Set number of cores (use available cores - 1, or 2 if only 1 available)
# num_cores <- max(1, parallel::detectCores() - 1)
num_cores <- 1 # Force single core to avoid serialization issues with pwalign in parallel mode for DNA
message("Using ", num_cores, " cores.")

# --- 1. RNA Analysis ---
message("\nStarting RNA analysis...")
rna_output_dir <- file.path(output_dir, "rna")
if (!dir.exists(rna_output_dir)) dir.create(rna_output_dir)

# Get example RNA data path
rna_fast5_dir <- system.file('extdata', 'rna', package = 'tailfindr')
message("RNA input directory: ", rna_fast5_dir)

# Run find_tails for RNA
# This demonstrates basic usage for RNA
df_rna <- find_tails(fast5_dir = rna_fast5_dir,
                     save_dir = rna_output_dir,
                     csv_filename = 'rna_tails.csv',
                     num_cores = num_cores)

message("RNA analysis complete. Results saved to: ", rna_output_dir)
print(head(df_rna))

# --- 2. cDNA (DNA) Analysis with Plots ---
message("\nStarting cDNA analysis with plots...")
cdna_output_dir <- file.path(output_dir, "cdna")
if (!dir.exists(cdna_output_dir)) dir.create(cdna_output_dir)

# Get example cDNA data path
cdna_fast5_dir <- system.file('extdata', 'cdna', 'basecalled_with_standard_model', 'polya_reads', package = 'tailfindr')
message("cDNA input directory: ", cdna_fast5_dir)

# Run find_tails for cDNA with plotting enabled
# This demonstrates:
# - DNA support
# - Plotting (save_plots = TRUE)
# - Interactive plots (plotting_library = 'rbokeh')
# - Debug traces (plot_debug_traces = TRUE)
df_cdna <- find_tails(fast5_dir = cdna_fast5_dir,
                      save_dir = cdna_output_dir,
                      csv_filename = 'cdna_tails.csv',
                      num_cores = num_cores,
                      save_plots = FALSE, # Try disabling plots to see if serialization fails
                      plot_debug_traces = FALSE, # Enable debug traces
                      plotting_library = 'rbokeh') # Use rbokeh for interactive plots

message("cDNA analysis complete. Results saved to: ", cdna_output_dir)
print(head(df_cdna))

# --- 3. Poly(T) DNA Analysis ---
message("\nStarting Poly(T) DNA analysis...")
polyt_output_dir <- file.path(output_dir, "polyt")
if (!dir.exists(polyt_output_dir)) dir.create(polyt_output_dir)

# Get example Poly(T) data path
polyt_fast5_dir <- system.file('extdata', 'cdna', 'basecalled_with_standard_model', 'polyt_reads', package = 'tailfindr')
message("Poly(T) input directory: ", polyt_fast5_dir)

# Run find_tails for Poly(T) reads
df_polyt <- find_tails(fast5_dir = polyt_fast5_dir,
                       save_dir = polyt_output_dir,
                       csv_filename = 'polyt_tails.csv',
                       num_cores = num_cores)

message("Poly(T) analysis complete. Results saved to: ", polyt_output_dir)
print(head(df_polyt))

message("\nAll analyses completed successfully!")
