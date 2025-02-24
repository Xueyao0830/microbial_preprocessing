#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J 389927_compress_clean_fastq_clean
#SBATCH -t 30:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/389927_compress_clean_fastq_clean_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/389927_compress_clean_fastq_clean_%j.err
#SBATCH --mail-user=xueyao.wang@ki.se

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

#BIOPROJECT="BIOPROJECT_PLACEHOLDER"
BIOPROJECT="PRJDB4176"

INPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics"

FOLDER_NAME="${INPUT_DIR}/${BIOPROJECT}"

ARCHIVE_NAME="$INPUT_DIR/${BIOPROJECT}_final.tar.gz"

# Compress the folder using pigz for parallel compression
tar --use-compress-program=pigz -cf "$ARCHIVE_NAME" "$FOLDER_NAME"

# Verify the compressed file
if tar -tzf "$ARCHIVE_NAME" > /dev/null; then
  echo "Compression successful and verification passed."

  # Delete the original folder
  rm -rf "$FOLDER_NAME"
  echo "Original folder deleted."
else
  echo "Verification failed. Original folder not deleted."
  exit 1
fi

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"