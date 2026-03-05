#' Load a group of sample(s)
#' 
#' This function loads the output files from the same group of sample(s)  
#' @rdname load_data
#' @param  infile  path to the input IsoQuant output files of a group of sample(s)
#' @param  group name or condition of sample(s) imported from infile  
#' @return a table including all the reads from this group of sample(s)
#' @export

load_data <- function(infile,group=group){
  # Initialize an empty list to store results
  reads_list <- list()
  
  # Define a helper function to read and process files for a given sample
  process_sample <- function(sample, group) {
    base::gc()
    # Read gene reads and remove duplicates
    file1 <- list.files(path = sample, pattern="OUT.read_assignments.tsv",full.names = T)
    sample_gene_reads <- data.table::fread(file1, header = TRUE, sep = "\t", skip = 2)
    colnames(sample_gene_reads)[1] <- "read_id"
    sample_gene_reads <- unique(sample_gene_reads[,c(1,3,5)], by = "read_id")
    
    # Read bed file and remove duplicates
    file2 <- list.files(path = sample, pattern="OUT.corrected_reads.bed",full.names = T)
    sample_reads_bed <- data.table::fread(file2, header = TRUE, sep = "\t")
    colnames(sample_reads_bed)[1] <- "chrom"
    sample_reads_bed <- unique(sample_reads_bed[,1:4], by = "name")
    
    # Merge data
    sample_reads <- merge(sample_gene_reads, sample_reads_bed, by.x = "read_id", by.y = "name", all.x = TRUE)
    
    # Add columns for sample and treatment
    sample_reads[, sample := sample]
    sample_reads[, treatment := group]
    return(sample_reads)
  }
  
  # Process samples from infile1 (group1)
  for (sample in infile) {
    message("Collecting data from ", group, " group")
    sample_data <- process_sample(sample, group)
    reads_list[[length(reads_list) + 1]] <- sample_data
  }
  
  
  # Combine all processed data into a single data.table
  reads_all <- data.table::rbindlist(reads_list)
  reads_all[, (base::setdiff(names(reads_all), c("chromStart", "chromEnd")) ) := lapply(.SD, as.factor), .SDcols = setdiff(names(reads_all), c("chromStart", "chromEnd"))]
  reads_all <-subset(reads_all,gene_id!=".")
  reads_all$read_id <-seq_len(nrow(reads_all))
  return(reads_all)
}