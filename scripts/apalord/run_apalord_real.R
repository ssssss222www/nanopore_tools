# /mnt/TWET-20250901A/ymm/scripts/apalord/run_apalord_real.R
# This script runs the APALORD analysis on real DRS data.

message("Step 0: Initializing Environment...")
library(APALORD)
library(ggplot2)
library(data.table)

# Set output directory
out_dir <- "/media/user/Elements_YMM/Nanopore/results/APALORD"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}
message("Output directory: ", out_dir)

# Step 1: Load GTF Annotation
message("Step 1: Loading GTF Annotation...")
gtf_file <- "/media/user/Elements_YMM/Nanopore/data/reference/gtf/TAIR10.gtf"

if (!file.exists(gtf_file)) {
    stop("GTF file not found at: ", gtf_file)
}
message("GTF file found at: ", gtf_file)

# Use 4 cores for processing
cores_to_use <- 4
gene_reference <- load_gtf(gtf_file, cores = cores_to_use)

# Step 2: Load Samples
message("Step 2: Loading Samples...")

# Define sample paths
control_files <- c(
    "/media/user/Elements_YMM/Nanopore/data/AT_vir/control/col0_1/isoquant/OUT",
    "/media/user/Elements_YMM/Nanopore/data/AT_vir/control/col0_4/isoquant/OUT"
)
treatment_files <- c(
    "/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/isoquant/OUT",
    "/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_4/isoquant/OUT"
)

# Check if files exist
for (path in c(control_files, treatment_files)) {
    if (!file.exists(file.path(path, "OUT.read_assignments.tsv"))) {
        stop("Missing OUT.read_assignments.tsv in: ", path)
    }
}

# Load samples with group separation
reads <- load_samples(infile1 = control_files, infile2 = treatment_files, 
                      group1 = "Control", group2 = "Treatment")
message("Samples loaded successfully.")

# Step 3: PAS Calling
message("Step 3: PAS Calling...")
PAS_data <- PAS_calling(gene_reference, reads, cores = cores_to_use, direct_RNA = TRUE)

# Save PAS data
pas_file <- file.path(out_dir, "PAS_Treatment_Control.bed")
write.table(PAS_data, file = pas_file, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")
message("PAS Calling completed. Output saved to: ", pas_file)

# Step 4: Internal Priming Check
message("Step 4: Checking Internal Priming...")
genome_file <- "/media/user/Elements_YMM/Nanopore/data/reference/fa/TAIR10.fa"
if (file.exists(genome_file)) {
    tryCatch({
        Internal_priming_res <- Internal_priming(PAS_data, pattern = "post", genome = genome_file)
        if (is.data.frame(Internal_priming_res)) {
            write.table(Internal_priming_res, file.path(out_dir, "Internal_priming.tsv"), 
                        quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
        }
        message("Internal Priming Check completed.")
    }, error = function(e) {
        message("Error in Internal_priming: ", e$message)
    })
} else {
    message("Genome file not found, skipping Internal Priming check.")
}

# Step 5: PAU Quantification
message("Step 5: Quantifying PAU by sample...")
PAU_data <- PAU_by_sample(gene_reference, reads, cores = cores_to_use, direct_RNA = TRUE)

# Save PAU data
pau_file <- file.path(out_dir, "PAU_by_sample_Treatment_Control.tsv")
write.table(PAU_data, file = pau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
message("PAU Quantification completed. Output saved to: ", pau_file)

# Step 6: Differential PAU Analysis
message("Step 6: Differential PAU Analysis...")
PAU_test_data <- PAU_test(PAU_data, reads, P_cutoff = 0.05)

# Save PAU test data
pau_test_file <- file.path(out_dir, "PAU_test_data_all.tsv")
write.table(PAU_test_data, file = pau_test_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
message("Differential PAU Analysis completed. Output saved to: ", pau_test_file)

# Step 7: Distal/Proximal PAS Shifts
message("Step 7: Distal/Proximal PAS Shifts...")
dPAU_test_data <- tryCatch({
    res <- end_PAS_examine(
        PAU_data, 
        reads, 
        P_cutoff = 0.2,
        control = "Control",
        experimental = "Treatment",
        position = "distal", 
        type = "delta",
        cores = cores_to_use
    )
    
    dpau_file <- file.path(out_dir, "dPAU_test_data.tsv")
    write.table(res, file = dpau_file, quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
    message("Distal PAS shift analysis completed. Output saved to: ", dpau_file)
    res
    
}, error = function(e) {
    message("Error in end_PAS_examine: ", e$message)
    return(NULL)
})

# Helper function to prepare data for APA_plot and gene_explore
prepare_apa_table <- function(dpau_data) {
    if (is.null(dpau_data) || nrow(dpau_data) == 0) return(NULL)
    
    dt <- as.data.table(dpau_data)
    
    # 1. Rename columns to match APA_plot expectation
    if ("mean of Control" %in% names(dt)) setnames(dt, "mean of Control", "PAUs_Control")
    if ("mean of Treatment" %in% names(dt)) setnames(dt, "mean of Treatment", "PAUs_Treatment")
    if ("PAU_change" %in% names(dt)) setnames(dt, "PAU_change", "APA_change")
    
    # 2. Calculate number_of_PAS
    dt[, number_of_PAS := .N, by = gene_id]
    
    # 3. Clean NA/Inf values
    dt <- dt[!is.na(pvalue) & !is.infinite(pvalue)]
    dt <- dt[!is.na(APA_change) & !is.infinite(APA_change)]
    
    return(dt)
}

# Helper function to prepare collapsed gene-level table for gene_explore
prepare_gene_table <- function(dt) {
    if (is.null(dt) || nrow(dt) == 0) return(NULL)
    # Collapse PAS positions and PAUs per gene
    gene_dt <- dt[, .(
        PAS_coordinates = paste(PAS, collapse = ","),
        PAU_changes = paste(APA_change, collapse = ","),
        PAUs_Control = paste(PAUs_Control, collapse = ","),
        PAUs_Treatment = paste(PAUs_Treatment, collapse = ","),
        gene_name = first(gene_name),
        chrom = first(chrom),
        strand = first(strand)
    ), by = gene_id]
    
    return(gene_dt)
}

# Step 8: APA Plot
message("Step 8: Generating APA Plot...")
APA_table_gene <- tryCatch({
    if (!is.null(dPAU_test_data)) {
        APA_table_plot <- prepare_apa_table(dPAU_test_data)
        
        if (!is.null(APA_table_plot) && nrow(APA_table_plot) > 0) {
            # Check if we have valid data for plotting
            if (sum(APA_table_plot$number_of_PAS > 1) > 0) {
                pdf(file.path(out_dir, "APA_plot.pdf"))
                APA_plot(copy(APA_table_plot), P_cutoff = 0.05, delta = 0.1)
                dev.off()
                message("APA Plot generated.")
            } else {
                message("No genes with > 1 PAS found in filtered data, skipping APA Plot.")
            }
            
            # Prepare for Gene Explore and return it
            prepare_gene_table(APA_table_plot)
        } else {
            message("Empty APA_table_plot, skipping APA Plot.")
            NULL
        }
    } else {
        message("dPAU_test_data missing, skipping APA Plot.")
        NULL
    }
}, error = function(e) {
    message("Error in APA_plot preparation or execution: ", e$message)
    return(NULL)
})

# Step 9: APA Profile
message("Step 9: Generating APA Profile...")
tryCatch({
    pdf(file.path(out_dir, "APA_profile.pdf"))
    APA_profile(gene_reference, reads, control = "Control", experimental = "Treatment", 
                min_counts = 10, min_reads = 5, min_percent = 1, cores = cores_to_use, direct_RNA = TRUE)
    dev.off()
    message("APA Profile generated.")
}, error = function(e) {
    message("Error in APA_profile: ", e$message)
})

# Step 10: Gene Explore
message("Step 10: Gene Explore (Top significant genes)...")
tryCatch({
    if (!is.null(APA_table_gene) && nrow(APA_table_gene) > 0) {
        # Select top genes based on p-value from original dPAU_test_data
        dt_orig <- as.data.table(dPAU_test_data)
        if (nrow(dt_orig) > 0) {
            # Sort by pvalue
            dt_orig <- dt_orig[order(pvalue)]
            top_genes <- unique(head(dt_orig$gene_id, 5))
            top_genes <- as.character(top_genes) # Ensure character
            
            # Ensure top_genes exist in APA_table_gene
            top_genes <- intersect(top_genes, APA_table_gene$gene_id)
            
            if (length(top_genes) > 0) {
                pdf(file.path(out_dir, "Gene_Explore.pdf"))
                gene_explore(gene_reference, reads, gene_list = top_genes, APA_table = APA_table_gene, direct_RNA = TRUE)
                dev.off()
                message("Gene Explore plots generated for: ", paste(top_genes, collapse = ", "))
            } else {
                message("No top genes found in prepared table for exploration.")
            }
        }
    } else {
        message("APA_table_gene is missing or empty, skipping Gene Explore.")
    }
}, error = function(e) {
    message("Error in gene_explore: ", e$message)
})

message("APALORD analysis pipeline finished successfully.")
