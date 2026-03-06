# run_apalord_real.R

message("Step 0: Initializing Environment...")
library(APALORD)
library(ggplot2)

# 输出目录（本地）
out_dir <- "/mnt/TWET-20250901A/ymm/results/apalord/output"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Step 1: 加载 GTF
message("Step 1: Loading GTF Annotation...")
gtf_file <- "/media/user/Elements_YMM/Nanopore/data/reference/gtf/TAIR10.gtf"
if (!file.exists(gtf_file)) stop("GTF file not found: ", gtf_file)
gene_reference <- load_gtf(gtf_file, cores = 4)

# Step 2: 加载样本（路径指向本地 IsoQuant 输出）
message("Step 2: Loading Samples...")
sample1 <- c(
    "/mnt/TWET-20250901A/ymm/results/apalord/isoquant/col0_1/OUT",
    "/mnt/TWET-20250901A/ymm/results/apalord/isoquant/col0_4/OUT"
)
sample2 <- c(
    "/mnt/TWET-20250901A/ymm/results/apalord/isoquant/vir1_1/OUT",
    "/mnt/TWET-20250901A/ymm/results/apalord/isoquant/vir1_4/OUT"
)
reads <- load_samples(sample1, sample2, group1 = "Control", group2 = "Treatment")

# Step 3: PAS Calling
message("Step 3: PAS Calling...")
PAS_data <- PAS_calling(gene_reference, reads, cores = 4, direct_RNA = TRUE)
write.table(PAS_data, file.path(out_dir, "PAS_Treatment_Control.bed"),
            quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")

# Step 4: Internal Priming Check（可选）
message("Step 4: Internal Priming Check...")
tryCatch({
    genome_file <- "/media/user/Elements_YMM/Nanopore/data/reference/total_ref.fa"
    Internal_priming_res <- Internal_priming(PAS_data, pattern = "post", genome = genome_file)
    write.table(Internal_priming_res, file.path(out_dir, "Internal_priming.tsv"),
                quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
}, error = function(e) message("Internal priming error: ", e$message))

# Step 5: PAU 定量
message("Step 5: PAU Quantification...")
PAU_data <- PAU_by_sample(gene_reference, reads, cores = 4, direct_RNA = TRUE)
write.table(PAU_data, file.path(out_dir, "PAU_by_sample.tsv"),
            quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")

# Step 6: 差异 PAU 分析
message("Step 6: Differential PAU Analysis...")
PAU_test_data <- PAU_test(PAU_data, reads, P_cutoff = 0.05)
write.table(PAU_test_data, file.path(out_dir, "PAU_test_data_all.tsv"),
            quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")

# Step 7: APA Profile + Plot（核心步骤）
message("Step 7: APA Profiling...")
APA_data <- APA_profile(gene_reference, reads,
                         control = "Control", experimental = "Treatment",
                         cores = 4, direct_RNA = TRUE)
write.table(APA_data, file.path(out_dir, "APA_data.tsv"),
            quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
pdf(file.path(out_dir, "APA_plot.pdf"), 7, 7)
APA_gene_table <- APA_plot(APA_data)
dev.off()
write.table(APA_gene_table, file.path(out_dir, "APA_gene_table.tsv"),
            quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")

# Step 8: Distal/Proximal PAS Shifts
message("Step 8: Distal/Proximal PAS Shifts...")
tryCatch({
    dPAU <- end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                             control = "Control", experimental = "Treatment",
                             position = "distal", type = "FC")
    write.table(dPAU, file.path(out_dir, "dPAU_distal.tsv"),
                quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
}, error = function(e) message("Distal PAS error: ", e$message))

tryCatch({
    pPAU <- end_PAS_examine(PAU_data, reads, P_cutoff = 0.2,
                             control = "Control", experimental = "Treatment",
                             position = "proximal", type = "delta")
    write.table(pPAU, file.path(out_dir, "dPAU_proximal.tsv"),
                quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
}, error = function(e) message("Proximal PAS error: ", e$message))

# Step 9: Gene Explore（选取前5个显著基因）
message("Step 9: Gene Explore...")
tryCatch({
    top_genes <- head(unique(PAU_test_data$gene_id[order(PAU_test_data$pvalue)]), 5)
    pdf(file.path(out_dir, "Gene_Explore.pdf"), 7, 7)
    gene_explore(gene_reference, reads, gene_list = top_genes,
                 APA_table = APA_data, direct_RNA = TRUE)
    dev.off()
    message("Gene Explore完成，基因：", paste(top_genes, collapse = ", "))
}, error = function(e) message("Gene Explore error: ", e$message))

message("APALORD pipeline finished!")