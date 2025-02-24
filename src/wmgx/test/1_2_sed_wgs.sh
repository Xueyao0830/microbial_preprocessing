#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J sed_SUBSTITUTION_BIO_ID
#SBATCH -t 6:00:00
#SBATCH --cpus-per-task=15
#SBATCH --mem=200G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/SUBSTITUTION_BIO_ID_sed_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/SUBSTITUTION_BIO_ID_sed_%j.err

module load parallel/20181122-nsc1

export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/sratoolkit.3.1.1-ubuntu64/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/seqtk
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/edirect

# Update with your output directory path
BIOPROJECT="SUBSTITUTION_BIO_ID"

CPUS=20  # Number of CPUs to use

# Define variables
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
OUTPUT_METADATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT"
LOG_FILE="$OUTPUT_DIR/download.log"
META_CSV_FILE="$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_METADATA_DIR"
touch "$LOG_FILE"

echo "Job started on $(hostname) at $(date)" >> "$LOG_FILE"
echo "Downloading FASTQ files for BioProject: $BIOPROJECT" >> "$LOG_FILE"
echo "Output directory: $OUTPUT_DIR" >> "$LOG_FILE"

# Fetch run info using esearch and efetch, extract SRR IDs and Library Strategy
esearch -db sra -query $BIOPROJECT | efetch -format runinfo > $META_CSV_FILE
SRR_IDS_AND_LibraryStrategy=$(awk -F, 'NR>1 {print $1, $13}' "$META_CSV_FILE")

# Define function for sed processing of fastq files
sed_fastq_id() {
    local SRR_ID=$1
    local PREFIX=${SRR_ID:0:3}
    for suffix in 0 1 2; do
        pigz -dc "$OUTPUT_DIR/${SRR_ID}_${suffix}_WGS.fastq.gz" | \
        sed "/^+${PREFIX}/s/\(^+\).*/\1/" | \
        pigz -p $CPUS > "$OUTPUT_DIR/${SRR_ID}_${suffix}_clean_final.fastq.gz"
    done
}

# Define function for checking line counts
check_fastq_clean_lines() {
    local all_files_match=true

    for SRR_ID in $SRR_IDS; do
        for suffix in 0 1 2; do
            original_file="$OUTPUT_DIR/${SRR_ID}_${suffix}_WGS.fastq.gz"
            clean_file="$OUTPUT_DIR/${SRR_ID}_${suffix}_clean_final.fastq.gz"

            # Count lines in the original and cleaned files
            original_lines=$(zcat "$original_file" | wc -l)
            clean_lines=$(zcat "$clean_file" | wc -l)

            if [[ $original_lines -ne $clean_lines ]]; then
                echo "Line count mismatch for ${original_file} and ${clean_file}" >> $LOG_FILE
                all_files_match=false
            fi
        done
    done

    # If all files match, delete the original files
    if $all_files_match; then
        echo "All files match, deleting original files..." >> $LOG_FILE
        for SRR_ID in $SRR_IDS; do
            for suffix in 0 1 2; do
                rm "$OUTPUT_DIR/${SRR_ID}_${suffix}_wgs.fastq.gz"
            done
        done
    else
        echo "Some files did not match, original files were not deleted." >> $LOG_FILE
    fi
}

# Run sed_fastq_id on each SRR_ID
for SRR_ID in $(echo "$SRR_IDS_AND_LibraryStrategy" | cut -d ',' -f 1); do
    sed_fastq_id "$SRR_ID"
done

# Check if all files are processed correctly
check_fastq_clean_lines


sbatch 2_kneaddata_parallel.sh

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"
echo "Sed processing is successfully done." >> "$LOG_FILE"