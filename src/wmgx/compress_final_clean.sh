#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J PRJEB37017_compress_clean_fastq
#SBATCH -t 30:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/PRJEB37017_compress_clean_fastq_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/PRJEB37017_compress_clean_fastq_%j.err
#SBATCH --mail-user=xueyao.wang@ki.se



# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

#BIOPROJECT="BIOPROJECT_PLACEHOLDER"
BIOPROJECT="PRJEB37017"

INPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics"

FOLDER_NAME="${INPUT_DIR}/${BIOPROJECT}"



# Change to the directory
cd "$FOLDER_NAME"
for file in *.fastq; do
    original_lines=$(wc -l < "$file")
    compressed_lines=$(zcat "$file.gz" | wc -l) 

    if [ "$original_lines" -eq "$compressed_lines" ]; then
        echo "$file.gz has been created successfully and verified."
        rm "$file"
    fi
done

# Compress each FASTQ file


# Compress each FASTQ file and delete the original if the compression is successful
for file in *.fastq; do
    echo "Compressing $file"
    if gzip "$file"; then
        echo "$file has been compressed successfully."
    else
        echo "Error: $file could not be compressed."
    fi
done

# Verify each compressed file
for file in *.fastq; do
    if [ -f "${file}.gz" ]; then
        echo "$file.gz has been created successfully."
    else
        echo "Error: $file.gz was not created."
    fi
done

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"
