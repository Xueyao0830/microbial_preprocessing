#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J OEP001340
#SBATCH -t 00:30:00
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16000
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/log/%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/log/%j.err

# Load necessary modules
module load parallel/20181122-nsc1  # Load GNU parallel

# Define variables
# Define variables
DATASET_ID='OEP001340'

WORK_DIR="/proj/naiss2024-6-169/users/x_xwang/src"
DATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/${DATASET_ID}"
FILE="/proj/naiss2024-6-169/users/x_xwang/script/rawdata/metagenomics/1720601313948.txt"
 
# Create necessary directories
mkdir -p $DATA_DIR

# Extract URLs and download files
awk -F'\t' 'NR==1 {for (i=1; i<=NF; i++) if ($i == "url") col=i} NR>1 {print $col}' $FILE | parallel -j 10 wget -P $DATA_DIR {}

echo "Download completed. Verifying the number of downloaded files..."

# Count the number of URLs in the CSV file (excluding the header)
EXPECTED_COUNT=$(awk -F'\t' 'NR>1 {print $col}' $FILE | wc -l)

# Count the number of files downloaded
ACTUAL_COUNT=$(ls -1 $DATA_DIR | wc -l)

# Compare the counts and report
if [[ $EXPECTED_COUNT -eq $ACTUAL_COUNT ]]; then
  echo "All files downloaded successfully. ($ACTUAL_COUNT files)"
else
  echo "Error: Mismatch in the number of downloaded files."
  echo "Expected: $EXPECTED_COUNT files, but found: $ACTUAL_COUNT files."
fi

echo "Download and verification process completed."

# Move the CSV file to the data directory
mv $FILE $DATA_DIR