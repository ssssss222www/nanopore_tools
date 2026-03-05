# /mnt/TWET-20250901A/ymm/scripts/APALORD/run_apalord_example.R
# This script runs the full APALORD example workflow.

# Step 0: Initialize Environment
message("Step 0: Initializing Environment...")
library(APALORD)
library(ggplot2) # For plotting if needed

# Set output directory
out_dir <- "/mnt/TWET-20250901A/ymm/results/APALORD"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}
message("Output directory: ", out_dir)

# Step 1: Load GTF Annotation
message("Step 1: Loading GTF Annotation...")
extdata_path <- system.file("extdata", package = "APALORD")
gtf_file <- paste0(extdata_path, "/hg38_chr21.gtf.gz")

if (!file.exists(gtf_file)) {
    # Fallback to local repo if system.file doesn't find it (sometimes happens with non-standard installs)
    message("Warning: GTF file not found in package installation. Trying local repository path...")
    extdata_path <- "/mnt/TWET-20250901A/ymm/APALORD/inst/extdata"
    gtf_file <- paste0(extdata_path, "/hg38_chr21.gtf.gz")
}

if (!file.exists(gtf_file)) {
    stop("GTF file not found at: ", gtf_file)
}
message("GTF file found at: ", gtf_file)

# Using 2 cores to be safe in this environment, though README says 5
cores_to_use <- 2 
gene_reference <- load_gtf(gtf_file, cores = cores_to_use)

# Step 2: Load Samples
message("Step 2: Loading Samples...")
sample1 <- c(paste0(extdata_path, "/D0/rep1"), paste0(extdata_path, "/D0/rep2"), paste0(extdata_path, "/D0/rep3"))
sample2 <- c(paste0(extdata_path, "/D7/rep1"), paste0(extdata_path, "/D7/rep2"), paste0(extdata_path, "/D7/rep3"))

# Verify sample paths
if (!all(dir.exists(c(sample1, sample2)))) {
    stop("One or more sample directories do not exist. Checked paths:\n", 
         paste(c(sample1, sample2), collapse = "\n"))
}

reads <- load_samples(sample1, sample2, group1 = "D0", group2 = "D7")

# Step 3: PAS Calling
message("Step 3: PAS Calling...")
PAS_data <- PAS_calling(gene_reference, reads, cores = cores_to_use, direct_RNA = TRUE)
pas_file <- file.path(out_dir, "PAS_D7_D0.bed")
write.table(PAS_data, file = pas_file, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")
message("PAS Calling completed. Output saved to: ", pas_file)

# Step 4: PAU Quantification
message("Step 4.1: Quantifying PAU by sample...")
PAU_data <- PAU_by_sample(gene_reference, reads, cores = cores_to_use, direct_RNA = TRUE)
pau_file <- file.path(out_dir, "PAU_by_sample_D7_D0.tsv")
write.table(PAU_data, file = pau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
message("PAU Quantification completed. Output saved to: ", pau_file)

message("Step 4.2: Differential PAU Analysis...")
PAU_test_data <- PAU_test(PAU_data, reads, P_cutoff = 0.05)
pau_test_file <- file.path(out_dir, "hESC_PAU_test_data_all.tsv")
write.table(PAU_test_data, file = pau_test_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
message("Differential PAU Analysis completed. Output saved to: ", pau_test_file)

message("Step 4.3: Distal/Proximal PAS Shifts...")
# The README mentions these functions for examining shifts
# Note: Using tryCatch to handle potential errors if data doesn't have enough significance for some tests
tryCatch({
    dPAU_test_data <- APALORD::end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                                             control = "D0", experimental = "D7", position = "distal", type = "FC")
    dpau_file <- file.path(out_dir, "dPAU_test_data.tsv")
    write.table(dPAU_test_data, file = dpau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    message("Distal PAS shift analysis completed.")
}, error = function(e) {
    message("Error in Distal PAS shift analysis: ", e$message)
})

tryCatch({
    pPAU_test_data <- APALORD::end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                                             control = "D0", experimental = "D7", position = "proximal", type = "delta")
    ppau_file <- file.path(out_dir, "pPAU_test_data.tsv")
    write.table(pPAU_test_data, file = ppau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    message("Proximal PAS shift analysis completed.")
}, error = function(e) {
    message("Error in Proximal PAS shift analysis: ", e$message)
})

# Step 5: APA Profiling
message("Step 5: APA Profiling...")
# Based on README, APA_profile needs control and experimental arguments
tryCatch({
    APA_data <- APA_profile(gene_reference, reads, control = "D0", experimental = "D7", cores = cores_to_use, direct_RNA = TRUE)
    apa_file <- file.path(out_dir, "APA_data_hES_D7_D0.tsv")
    write.table(APA_data, file = apa_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    
    # Generate plot data/table
    APA_gene_table <- APA_plot(APA_data)
    apa_table_file <- file.path(out_dir, "APA_gene_table_hES_D7_D0.tsv")
    write.table(APA_gene_table, file = apa_table_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    
    # Also save the plot itself if possible, though APA_plot returns a table according to README comment?
    # README says: "The APA_plot function generates a Vocanol plot showing the transcriptome-wide APA changes."
    # But the variable assignment `APA_gene_table <- APA_plot(APA_data)` suggests it returns data.
    # We will check if it produces a plot object or side effect.
    # To be safe, we open a PDF device.
    pdf_file <- file.path(out_dir, "APA_volcano_plot.pdf")
    pdf(pdf_file)
    print(APA_plot(APA_data)) # Try printing in case it returns a ggplot object
    dev.off()
    message("APA Profiling completed. Outputs saved to: ", apa_file, ", ", apa_table_file, ", ", pdf_file)
    
}, error = function(e) {
    message("Error in APA Profiling: ", e$message)
})

# Step 6: Single Gene Exploration
message("Step 6: Single Gene Exploration...")
genes_to_explore <- c("GART", "ENSG00000185658", "ZBTB21")
message("Exploring APA changes for genes: ", paste(genes_to_explore, collapse = ", "))

# Creating a PDF for the gene plots
gene_plot_file <- file.path(out_dir, "single_gene_plots.pdf")
pdf(gene_plot_file)

tryCatch({
    # The example calls it with a vector of genes
    gene_explore(gene_reference, reads, genes_to_explore, APA_table = APA_data, direct_RNA = TRUE)
    message("Single gene exploration executed.")
}, error = function(e) {
    message("Error in gene_explore: ", e$message)
})

dev.off()
message("Single gene exploration plots saved to: ", gene_plot_file)

message("APALORD full example workflow completed successfully!")
