# /mnt/TWET-20250901A/ymm/scripts/apalord/run_apalord_real.R
# This script runs the APALORD analysis on real DRS data.

# Step 0: Initialize Environment
message("Step 0: Initializing Environment...")
library(APALORD)
library(ggplot2)

# Set output directory
out_dir <- "/media/user/Elements_YMM/Nanopore/results/APALORD"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}
message("Output directory: ", out_dir)

# Step 1: Load GTF Annotation
message("Step 1: Loading GTF Annotation...")
# Using the TAIR10 GTF file found in the reference directory
gtf_file <- "/media/user/Elements_YMM/Nanopore/data/reference/gtf/TAIR10.gtf"

if (!file.exists(gtf_file)) {
    stop("GTF file not found at: ", gtf_file)
}
message("GTF file found at: ", gtf_file)

# Using 4 cores for real data processing
cores_to_use <- 4
gene_reference <- load_gtf(gtf_file, cores = cores_to_use)

# Step 2: Load Samples
message("Step 2: Loading Samples...")

# APALORD requires IsoQuant output files: "OUT.read_assignments.tsv" and "OUT.corrected_reads.bed"
# These files are not present in the provided directories.
# The user provided directories contain BAM files and FASTQ files, but not IsoQuant output.
# APALORD is designed to work with IsoQuant output.

# We need to run IsoQuant first or inform the user.
# However, the user asked to "use APALORD to process real DRS data".
# If APALORD requires IsoQuant output, we should check if we can run IsoQuant or if the data is already processed but located elsewhere.
# The `find` command didn't locate "OUT.read_assignments.tsv" in the data directories.

# Wait, looking at the previous error:
# "input= 必须是以下其中一种字符串: ... 或是本身就包含至少一个\n 或 \r的输入数据"
# This suggests fread failed to find the file or the file was empty.
# The load_samples function looks for "OUT.read_assignments.tsv" and "OUT.corrected_reads.bed" in the sample path.
# Since these files are missing, we cannot proceed with APALORD directly.

# Assuming the user wants us to run the full pipeline, we probably need to run IsoQuant first.
# But IsoQuant is a separate tool.
# Let's check if IsoQuant is available or if we should mock the input (not recommended for real data).

# Actually, the user might have expected APALORD to take BAM files directly?
# But the source code clearly shows it looks for specific file patterns.
# `file1 <- list.files(path = sample, pattern="OUT.read_assignments.tsv",full.names = T)`

# Let's check if there are any other files that might be the output of IsoQuant but named differently?
# The `ls -R` showed `all_samples.coverage_summary.txt`, `col0-1.samstat`, etc.
# These look like alignment stats, not IsoQuant output.

# We must inform the user about the missing IsoQuant output.
# However, as an autonomous agent, I should try to solve this if possible.
# Can I run IsoQuant? I need to check if it's installed.

# For now, I will add a check in the script and stop with a clear message if files are missing.
# And I will check for IsoQuant availability in the next step.

# Let's verify if `isoquant` is in the path.
# If so, I could add a step to run IsoQuant.
# If not, I have to report the missing prerequisite.

stop("APALORD requires IsoQuant output files (OUT.read_assignments.tsv and OUT.corrected_reads.bed) which are missing in the data directories. Please run IsoQuant on the data first.")

# Step 3: PAS Calling
message("Step 3: PAS Calling...")
PAS_data <- PAS_calling(gene_reference, reads, cores = cores_to_use, direct_RNA = TRUE)
pas_file <- file.path(out_dir, "PAS_Treatment_Control.bed")
write.table(PAS_data, file = pas_file, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")
message("PAS Calling completed. Output saved to: ", pas_file)

# Step 4: PAU Quantification
message("Step 4.1: Quantifying PAU by sample...")
PAU_data <- PAU_by_sample(gene_reference, reads, cores = cores_to_use, direct_RNA = TRUE)
pau_file <- file.path(out_dir, "PAU_by_sample_Treatment_Control.tsv")
write.table(PAU_data, file = pau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
message("PAU Quantification completed. Output saved to: ", pau_file)

message("Step 4.2: Differential PAU Analysis...")
PAU_test_data <- PAU_test(PAU_data, reads, P_cutoff = 0.05)
pau_test_file <- file.path(out_dir, "PAU_test_data_all.tsv")
write.table(PAU_test_data, file = pau_test_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
message("Differential PAU Analysis completed. Output saved to: ", pau_test_file)

message("Step 4.3: Distal/Proximal PAS Shifts...")
tryCatch({
    dPAU_test_data <- APALORD::end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                                             control = "Control", experimental = "Treatment", position = "distal", type = "FC")
    dpau_file <- file.path(out_dir, "dPAU_test_data.tsv")
    write.table(dPAU_test_data, file = dpau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    message("Distal PAS shift analysis completed.")
}, error = function(e) {
    message("Error in Distal PAS shift analysis: ", e$message)
})

tryCatch({
    pPAU_test_data <- APALORD::end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                                             control = "Control", experimental = "Treatment", position = "proximal", type = "delta")
    ppau_file <- file.path(out_dir, "pPAU_test_data.tsv")
    write.table(pPAU_test_data, file = ppau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    message("Proximal PAS shift analysis completed.")
}, error = function(e) {
    message("Error in Proximal PAS shift analysis: ", e$message)
})

# Step 5: APA Profiling
message("Step 5: APA Profiling...")
tryCatch({
    APA_data <- APA_profile(gene_reference, reads, control = "Control", experimental = "Treatment", cores = cores_to_use, direct_RNA = TRUE)
    apa_file <- file.path(out_dir, "APA_data_Treatment_Control.tsv")
    write.table(APA_data, file = apa_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    
    # Generate plot data/table
    APA_gene_table <- APA_plot(APA_data)
    apa_table_file <- file.path(out_dir, "APA_gene_table_Treatment_Control.tsv")
    write.table(APA_gene_table, file = apa_table_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    
    pdf_file <- file.path(out_dir, "APA_volcano_plot.pdf")
    pdf(pdf_file)
    print(APA_plot(APA_data))
    dev.off()
    message("APA Profiling completed. Outputs saved to: ", apa_file, ", ", apa_table_file, ", ", pdf_file)
    
}, error = function(e) {
    message("Error in APA Profiling: ", e$message)
})

# Step 6: Single Gene Exploration
message("Step 6: Single Gene Exploration...")
# Select top significant genes from PAU_test_data if available
if (exists("PAU_test_data") && !is.null(PAU_test_data) && nrow(PAU_test_data) > 0) {
    # Sort by p-value or significance if possible, here just taking first few unique genes
    genes_to_explore <- unique(PAU_test_data$gene_name)[1:min(5, length(unique(PAU_test_data$gene_name)))]
    genes_to_explore <- genes_to_explore[!is.na(genes_to_explore)]
    
    if (length(genes_to_explore) > 0) {
        message("Exploring APA changes for top genes: ", paste(genes_to_explore, collapse = ", "))
        
        gene_plot_file <- file.path(out_dir, "single_gene_plots.pdf")
        pdf(gene_plot_file)
        
        tryCatch({
            gene_explore(gene_reference, reads, genes_to_explore, APA_table = APA_data, direct_RNA = TRUE)
            message("Single gene exploration executed.")
        }, error = function(e) {
            message("Error in gene_explore: ", e$message)
        })
        
        dev.off()
        message("Single gene exploration plots saved to: ", gene_plot_file)
    } else {
        message("No valid genes found for exploration.")
    }
} else {
    message("No significant PAU changes found or PAU_test_data is empty. Skipping gene exploration.")
}

message("APALORD analysis on real data completed successfully!")
