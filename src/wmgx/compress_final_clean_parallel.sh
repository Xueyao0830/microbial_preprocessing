#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J PRJEB37017_compress_clean_fastq
#SBATCH -t 5:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/PRJEB37017_compress_clean_fastq_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/PRJEB37017_compress_clean_fastq_%j.err
#SBATCH --mail-user=xueyao.wang@ki.se

module load parallel/20181122-nsc1

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

#BIOPROJECT="BIOPROJECT_PLACEHOLDER"
BIOPROJECT="PRJEB37017"

INPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics"

FOLDER_NAME="${INPUT_DIR}/${BIOPROJECT}"



# Change to the directory
cd "$FOLDER_NAME" || exit

for file in *.fastq; do
    original_lines=$(wc -l < "$file")
    compressed_lines=$(zcat "$file.gz" | wc -l) 

    if [ "$original_lines" -eq "$compressed_lines" ]; then
        echo "$file.gz has been created successfully and verified."
        rm "$file"
    fi
done

# Function to compress and verify a single file
compress_and_verify() {
    local file=$1
    gzip "$file"
    original_lines=$(wc -l < "$file")
    compressed_lines=$(zcat "${file}.gz" | wc -l)
    if [ "$original_lines" -eq "$compressed_lines" ]; then
        echo "${file}.gz has been created successfully and verified."
    else
        echo "Error: Verification failed for ${file}.gz"
    fi
}

export -f compress_and_verify

# Compress and verify all FASTQ files in parallel
find . -name '*.fastq' | parallel --jobs 20 compress_and_verify {}

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"
