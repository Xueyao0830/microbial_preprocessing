#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J merg_SUBSTITUTION_BIO_ID
#SBATCH -t 20:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=200G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/2_2_merge_kd.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/2_2_merge_kd.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xueyao.wang@ki.se

source ~/.bashrc
conda activate mm_crc


module load parallel/20181122-nsc1

# Define and export necessary paths

BIOPROJECT="SUBSTITUTION_BIO_ID"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
RESULT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/result"
CPUS=20

MERGED_TSV="${RESULT_DIR}/${BIOPROJECT}_kneaddata_remove_low_reads_merge_samples.tsv"
RM_LOW_READS_SRC="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/utils/kneaddata_remove_low_reads_merge_samples.py"

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

mkdir -p $MERGED_DIR

# Check if all kneaddata processes are completed successfully
all_done=true

for log_file in $(find "$OUTPUT_DIR" -type f -name "*_kneaddata.log"); do
    if grep -q "Final output files created" "$log_file"; then
        echo "Log file $log_file: kneaddata completed."
    else
        echo "Log file $log_file: kneaddata not completed."
    fi
done

if $all_done; then
    echo "All kneaddata processes completed. Proceeding with merging."

    # Run the Python script to filter and merge samples

    python ${RM_LOW_READS_SRC} "${OUTPUT_DIR}/${BIOPROJECT}_merged_kneaddata_reads_table.csv" "${META_CSV_FILE}" "${MERGED_TSV}"

    # Read the TSV file line by line
    while IFS=$'\t' read -r sample_id NCBI_accession extra_column1 extra_column2; do

        # Skip header or empty lines
        [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

        # Split the NCBI_accessions by commas
        IFS=',' read -r -a accession_array <<< "$NCBI_accession"
        
        # Debug: Print the accessions to check
        echo "Processing sample_id: $sample_id"
        echo "Accessions: ${accession_array[*]}"

        # Prepare output filenames
        forward_output="${MERGED_DIR}/${sample_id}_kneaddata_paired_1.fastq.gz"
        reverse_output="${MERGED_DIR}/${sample_id}_kneaddata_paired_2.fastq.gz"
        single_output="${MERGED_DIR}/${sample_id}_kneaddata_single.fastq.gz"

        # Initialize temporary files
        temp_forward=$(mktemp)
        temp_reverse=$(mktemp)
        temp_single=$(mktemp)

        # Assume paired-end by default
        is_paired=false

        # Iterate over each accession and build the file paths
        for accession in "${accession_array[@]}"; do
            if [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_WGS_clean_final_kneaddata_paired_1.fastq.gz" && -f "${OUTPUT_DIR}/${accession}/${accession}_1_WGS_clean_final_kneaddata_paired_2.fastq.gz" ]]; then
                is_paired=true
                # Concatenate paired-end files
                zcat "${OUTPUT_DIR}/${accession}/${accession}_1_WGS_clean_final_kneaddata_paired_1.fastq.gz" >> "$temp_forward"
                zcat "${OUTPUT_DIR}/${accession}/${accession}_1_WGS_clean_final_kneaddata_paired_2.fastq.gz" >> "$temp_reverse"
            elif [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_WGS_clean_final_kneaddata.fastq.gz" ]]; then
                # Concatenate single-end file
                zcat "${OUTPUT_DIR}/${accession}/${accession}_1_WGS_clean_final_kneaddata.fastq.gz" >> "$temp_single"
            else
                echo "Warning: No valid files found for accession: $accession"
            fi
        done

        # Compress the merged paired or single files with pigz
        if $is_paired; then
            pigz -p $CPUS < "$temp_forward" > "$forward_output"
            pigz -p $CPUS < "$temp_reverse" > "$reverse_output"
            rm "$temp_forward" "$temp_reverse"
        else
            pigz -p $CPUS < "$temp_single" > "$single_output"
            rm "$temp_single"
        fi

    done < "$MERGED_TSV"


else
    echo "Not all kneaddata processes are completed. Exiting."
    exit 1
fi

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))

# Convert runtime from seconds to hours
runtime_hours=$(echo "scale=2; $runtime / 3600" | bc)

echo "Job running time: $runtime_hours hours"