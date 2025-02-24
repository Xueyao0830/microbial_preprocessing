#!/usr/bin/env Rscript

library(curatedMetagenomicData)
library(dplyr)
library(curatedMetagenomicAnalyses)
library(SummarizedExperiment)

# Set the base directory for saving files
base_dir <- '/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/curated'
log_file <- file.path(base_dir, "processing_errors.log")

# Function to save data as CSV files based on the study name
save_curated_metagenomic_data <- function(study_name) {
  # Create a subfolder for the study name
  study_dir <- file.path(base_dir, study_name)
  dir.create(study_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Load metadata
  sampleMetadata <- sampleMetadata
  metadata <- sampleMetadata %>%
    filter(study_name == study_name)
  write.csv(metadata, file = file.path(study_dir, paste0(study_name, "_metadata.csv")), row.names = TRUE)

  # Load different datasets
  gene_families_re <- curatedMetagenomicData(paste0(study_name, ".gene_families"), dryrun = FALSE, counts = FALSE, rownames = "short")

  # Save assays with relative abundance
  save_assay_as_csv_re <- function(assay_object, assay_name) {
    if (length(assay_object) > 0) {
      se_object <- assay_object[[1]]  # Access the first element of the list
      data <- assays(se_object)[[assay_name]]
      df <- as.data.frame(as.matrix(data))
      write.csv(df, file = file.path(study_dir, paste0(study_name, "_", assay_name, "_re.csv")), row.names = TRUE)
    } else {
      warning(paste("No data available for", assay_name))
    }
  }
  
  save_assay_as_csv_re(gene_families_re, "gene_families")
}

# Main execution
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Please provide the path to the unique study names text file as a command line argument.")
}

# Read study names from the provided file
study_names_file <- args[1]
study_names <- readLines(study_names_file)  # Read study names from the specified text file

# Loop over each study name and save data
for (study_name in study_names) {
  cat("Processing study:", study_name, "\n")  # Print the study name being processed
  tryCatch({
    save_curated_metagenomic_data(study_name)
  }, error = function(e) {
    # Log the error to a file
    cat(paste(Sys.time(), "- Error processing study:", study_name, ":", e$message, "\n"), file = log_file, append = TRUE)
  })
}