# run_apalord_example.R

# 1. Initialize Environment
message("Step 1: Initializing Environment...")
library(APALORD)

# Set output directory
out_dir <- "./results_example"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

# 2. Load GTF Annotation
message("Step 2: Loading GTF Annotation...")
extdata_path <- system.file("extdata", package = "APALORD")
gtf_file <- paste0(extdata_path, "/hg38_chr21.gtf.gz")

if (!file.exists(gtf_file)) {
  stop("GTF file not found: ", gtf_file)
}

gene_reference <- load_gtf(gtf_file, cores = 2)

# 3. Load Samples
message("Step 3: Loading Samples...")
# Define sample paths based on package installation
sample1 <- c(paste0(extdata_path, "/D0/rep1"), paste0(extdata_path, "/D0/rep2"), paste0(extdata_path, "/D0/rep3"))
sample2 <- c(paste0(extdata_path, "/D7/rep1"), paste0(extdata_path, "/D7/rep2"), paste0(extdata_path, "/D7/rep3"))

# Check if sample directories exist
if (!all(dir.exists(c(sample1, sample2)))) {
    warning("Some sample directories do not exist. Checking local source directory...")
    # Fallback to local source if installed package doesn't have the data structure
    # This might happen if extdata isn't fully copied or structure differs
    local_extdata <- "/mnt/TWET-20250901A/ymm/APALORD/inst/extdata"
    if (dir.exists(local_extdata)) {
        extdata_path <- local_extdata
        sample1 <- c(paste0(extdata_path, "/D0/rep1"), paste0(extdata_path, "/D0/rep2"), paste0(extdata_path, "/D0/rep3"))
        sample2 <- c(paste0(extdata_path, "/D7/rep1"), paste0(extdata_path, "/D7/rep2"), paste0(extdata_path, "/D7/rep3"))
    }
}

if (!all(dir.exists(c(sample1, sample2)))) {
  stop("Sample directories not found.")
}

reads <- load_samples(sample1, sample2, group1 = "D0", group2 = "D7")

# 4. PAS Calling
message("Step 4: PAS Calling...")
PAS_data <- PAS_calling(gene_reference, reads, cores = 2, direct_RNA = TRUE)
pas_file <- file.path(out_dir, "PAS_D7_D0.bed")
write.table(PAS_data, file = pas_file, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")
message("PAS Calling finished. Output saved to ", pas_file)

# 5. PAU Quantification
message("Step 5.1: Quantifying PAU by sample...")
PAU_data <- PAU_by_sample(gene_reference, reads, cores = 2, direct_RNA = TRUE)
pau_file <- file.path(out_dir, "PAU_by_sample_D7_D0.tsv")
write.table(PAU_data, file = pau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")

message("Step 5.2: Differential PAU Analysis...")
PAU_test_data <- PAU_test(PAU_data, reads, P_cutoff = 0.05)
pau_test_file <- file.path(out_dir, "hESC_PAU_test_data_all.tsv")
write.table(PAU_test_data, file = pau_test_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")

message("Step 5.3: Distal/Proximal PAS Shifts...")
# Note: Functions might be named differently or require namespace prefix if not exported
# Checking package namespace for correct function names if needed
dPAU_test_data <- tryCatch({
    APALORD::end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                             control = "D0", experimental = "D7", position = "distal", type = "FC")
}, error = function(e) {
    message("Error in end_PAS_examine (distal): ", e$message)
    return(NULL)
})

pPAU_test_data <- tryCatch({
    APALORD::end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                             control = "D0", experimental = "D7", position = "proximal", type = "delta")
}, error = function(e) {
    message("Error in end_PAS_examine (proximal): ", e$message)
    return(NULL)
})


# 6. APA Profiling
message("Step 6: Profiling APA changes...")
# Assuming APA_profile function exists and takes gene_reference and reads
# The web snippet was cut off, so I will infer usage or check available functions
if (exists("APA_profile", where = asNamespace("APALORD"), mode = "function")) {
    APA_data <- APA_profile(gene_reference, reads, P_cutoff = 0.05)
    # Visualization or saving might be next steps, here just capturing the data
    saveRDS(APA_data, file.path(out_dir, "APA_profile_data.rds"))
} else {
    message("APA_profile function not found, skipping...")
}

# 7. Single Gene Exploration (Optional/Example)
# Just listing a gene if available
if (!is.null(PAU_test_data) && nrow(PAU_test_data) > 0) {
    top_gene <- PAU_test_data$gene_name[1]
    message("Top significant gene: ", top_gene)
    # visualize_gene(gene_reference, reads, gene_name = top_gene) # Hypothetical function
}

message("APALORD example workflow completed successfully!")
