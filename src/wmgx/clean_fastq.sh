#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J 4176_clean_fastq__clean
#SBATCH -t 10:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/PRJDB4176_clean_fastq_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/PRJDB4176_clean_fastq_%j.err
#SBATCH --mail-user=xueyao.wang@ki.se

#BIOPROJECT="BIOPROJECT_PLACEHOLDER"
BIOPROJECT="PRJDB4176"

source ~/.bashrc
conda activate mm_crc
#module load parallel/20181122-nsc1




INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
LOG_FILE="$OUTPUT_DIR/download.log"

gunzip $INPUT_FASTQ_DIR/*.fastq.gz

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

#gunzip $INPUT_FASTQ_DIR/*.fastq.gz


# Extract SRR IDs from the input directory
SRR_IDS=$(ls $INPUT_FASTQ_DIR/*_{1,2}.fastq | xargs -n 1 basename | cut -d '_' -f 1 | sort | uniq)



sed_fastq_id() {
    local SRR_ID=$1
    local PREFIX=${SRR_ID:0:3}
    for suffix in 1 2; do
        cat "$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}.fastq" | \
        sed '/^+${PREFIX}/s/\(^+\).*/\1/' > "$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}_clean.fastq"
    done
}

#export -f sed_fastq_id



check_fastq_clean_lines() {
    local SRR_ID=$1
    local all_files_match=true
    local PREFIX=${SRR_ID:0:3}

    for suffix in 1 2; do
        local original_file="$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}.fastq"
        local clean_file="$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}_clean.fastq"
        local clean_final_file="$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}_clean_final.fastq"

        # Count lines in original and cleaned files
        local original_lines=$(wc -l < "$original_file")
        local clean_lines=$(wc -l < "$clean_file")

        if [[ $original_lines -ne $clean_lines ]]; then
            echo "Line count mismatch for ${SRR_ID}_${suffix}.fastq and ${SRR_ID}_${suffix}_clean.fastq" >> $LOG_FILE
            all_files_match=false
            
            # Re-run sed to clean the file
            sed '/^+{PREFIX}/s/^+.*$/+/' "$original_file" > "$clean_file"
        fi

        if [[ $original_lines -eq $clean_lines ]]; then
            echo "Line count matches for ${SRR_ID}_${suffix}.fastq and ${SRR_ID}_${suffix}_clean.fastq" >> $LOG_FILE
            all_files_match=true
            mv "$clean_file" "$clean_final_file"
            # Optionally, delete original file if clean final file is created successfully
            if [[ -f "$clean_final_file" ]]; then
                rm "$original_file"
            fi
        fi
    done

    if $all_files_match; then
        echo "sed completed successfully for SRR ID: $SRR_ID"  >> $LOG_FILE
    fi
}

export -f check_fastq_clean_lines

for SRR_ID in $SRR_IDS; do
    check_fastq_clean_lines $SRR_ID
done






# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"
