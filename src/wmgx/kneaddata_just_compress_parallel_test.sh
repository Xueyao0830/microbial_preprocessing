#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J PRJEB10878_k_c
#SBATCH -t 3:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/PRJNA389927_kneaddata_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/PRJNA389927_kneaddata_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xueyao.wang@ki.se

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist
module load parallel/20181122-nsc1

# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC

BIOPROJECT="PRJEB10878"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Extract SRR IDs and Library Layouts from the CSV file
SRR_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $1, $16}' "$META_CSV_FILE")  # Adjust the column number for "Library Layout"

# Function to process single-end SRR ID
process_single_end_srr_id() {
    local SRR_ID=$1
    # Find the resulting FASTQ files in the output directory and gzip them
    for file in $OUTPUT_DIR/${SRR_ID}/*.fastq; do
        if [ -f "$file" ]; then
            gzip "$file"
        fi
    done
}

# Function to process paired-end SRR ID
process_paired_end_srr_id() {
    local SRR_ID=$1
    for file in $OUTPUT_DIR/${SRR_ID}/*.fastq; do
        if [ -f "$file" ]; then
            gzip "$file"
        fi
    done
}

# Function to check and process SRR ID
process_srr_id() {
    local SRR_ID=$1
    local LAYOUT=$2
    if [ "$LAYOUT" == "PAIRED" ]; then
        echo "Processing paired-end SRR ID: $SRR_ID"
        process_paired_end_srr_id $SRR_ID
    else
        echo "Processing single-end SRR ID: $SRR_ID"
        process_single_end_srr_id $SRR_ID
    fi
}

# Function to check if final output files were created
check_output() {
    local SRR_ID=$1
    if grep -q "Final output files created" $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata.log 2>/dev/null; then
        echo $SRR_ID
    fi
}

# Export functions for use with parallel
export -f process_single_end_srr_id
export -f process_paired_end_srr_id
export -f process_srr_id
export -f check_output

# Check each SRR ID for completion and re-process if needed
SRR_TO_REPROCESS=$(echo "$SRR_IDS_AND_LAYOUTS" | while read SRR_ID LAYOUT; do
    check_output $SRR_ID
done)

# Use parallel to reprocess SRR IDs if needed
if [ -n "$SRR_TO_REPROCESS" ]; then
    echo "Reprocessing SRR IDs: $SRR_TO_REPROCESS"
    echo "$SRR_IDS_AND_LAYOUTS" | parallel -j $CPUS --colsep ' ' process_srr_id {1} {2}
else
    echo "All SRR IDs compressed successfully."
fi

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"