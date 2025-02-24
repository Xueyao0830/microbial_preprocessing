#!/bin/bash

BIOPROJECT="PRJNA389927"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"

# Define the directory for merged files
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
MERGED_TSV="${MERGED_DIR}/${BIOPROJECT}_kneaddata_remove_low_reads_merge_samples.tsv"

# Run the Python script to filter and merge samples
python /proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/kneaddata_remove_low_reads_merge_samples.py "${OUTPUT_DIR}/${BIOPROJECT}_clean_final_merged_kneaddata_read_counts.tsv" "${META_CSV_FILE}" "${MERGED_DIR}/${BIOPROJECT}_kneaddata_remove_low_reads_merge_samples.tsv"
# Create the merged directory if it doesn't exist
mkdir -p "${MERGED_DIR}"

# Read the CSV file line by line
while IFS=',' read -r sample_id NCBI_accession; do

    # Skip header or empty lines
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    # Split the NCBI_accessions by commas
    IFS=',' read -r -a accession_array <<< "$NCBI_accession"

    # Prepare output filenames
    forward_output="${MERGED_DIR}/${sample_id}_1.fastq.gz"
    reverse_output="${MERGED_DIR}/${sample_id}_2.fastq.gz"

    # Initialize temporary files
    temp_forward=$(mktemp)
    temp_reverse=$(mktemp)

    # Iterate over each accession and build the file paths
    for accession in "${accession_array[@]}"; do
        # Concatenate forward reads
        if [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_1.fastq.gz" ]]; then
            cat "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_1.fastq.gz" >> "$temp_forward"
        fi
        # Concatenate reverse reads
        if [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_2.fastq.gz" ]]; then
            cat "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_2.fastq.gz" >> "$temp_reverse"
        fi
    done

    # Compress the merged files with pigz
    pigz -p 8 < "$temp_forward" > "$forward_output"
    pigz -p 8 < "$temp_reverse" > "$reverse_output"

    # Clean up temporary files
    rm "$temp_forward" "$temp_reverse"

done < "$MERGED_TSV"