#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J awk_parallel
#SBATCH --partition=main
#SBATCH -t 6:00:00 
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Load Conda environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Define paths
BIOPROJECT="PRJNA731589"
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS_awk"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Export required variables for GNU Parallel
export OUTPUT_DIR

# Function to process a single file
process_file() {
    INPUT_FILE=$1
    SAMPLE_ID=$(basename "$(dirname "$INPUT_FILE")")  # Extract sample ID (parent folder name)
    
    # Define sample output directory
    SAMPLE_OUTPUT_DIR="$OUTPUT_DIR/$SAMPLE_ID"
    mkdir -p "$SAMPLE_OUTPUT_DIR"

    # Define output file path
    OUTPUT_FILE="$SAMPLE_OUTPUT_DIR/$(basename "$INPUT_FILE")"

    # Process the file: transform the '+' line in the fastq.gz file
    zcat "$INPUT_FILE" | awk 'NR%4==3 {print "+"} NR%4!=3' | gzip > "$OUTPUT_FILE"

    # Print a status message
    echo "Processed $INPUT_FILE -> $OUTPUT_FILE"
}

export -f process_file

# Use GNU Parallel to process files in parallel, searching in each sample_id directory
find "$INPUT_DIR" -mindepth 2 -name "*.fastq.gz" | parallel -j $SLURM_CPUS_PER_TASK process_file {}

echo "✅ All files have been processed."













