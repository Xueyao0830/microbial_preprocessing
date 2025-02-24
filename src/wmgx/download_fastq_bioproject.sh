#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J BIOPROJECT_PLACEHOLDER
#SBATCH -t 20:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=20
#SBATCH --mem=60000
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/%j.err

module load parallel/20181122-nsc1

export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/sratoolkit.3.1.1-ubuntu64/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/seqtk
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/edirect

# Update with your output directory path
BIOPROJECT="PRJNA389927"  # Update with your BioProject accession

CPUS=16  # Number of CPUs to use

# Define variables
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
OUTPUT_METADATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT"
LOG_FILE="$OUTPUT_DIR/download.log"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_METADATA_DIR"
touch "$LOG_FILE"

echo "Job started on $(hostname) at $(date)" >> "$LOG_FILE"
echo "Downloading FASTQ files for BioProject: $BIOPROJECT" >> "$LOG_FILE"
echo "Output directory: $OUTPUT_DIR" >> "$LOG_FILE"

# Fetch run info using esearch and efetch, extract SRR IDs
SRR_IDS=$(esearch -db sra -query "$BIOPROJECT" | efetch -format runinfo | cut -d "," -f 1 | grep -v "Run")

esearch -db sra -query $BIOPROJECT | efetch -format runinfo > $OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt

# Count the number of SRR IDs
SRR_COUNT=$(echo "$SRR_IDS" | wc -l)

# Extract already written SRR IDs from the log file
if [ -f "$LOG_FILE" ]; then
    WRITTEN_SRRS=$(grep "Written " "$LOG_FILE" | sed 's/^.*for //' | sort | uniq)
else
    WRITTEN_SRRS=""
fi

# Function to check if an SRR ID is already written
is_written() {
    local srr_id=$1
    echo "$WRITTEN_SRRS" | grep -q "$srr_id"
}

# Export the function so it is available to parallel
export -f is_written

# Download FASTQ files
echo "$SRR_IDS" | parallel -j $CPUS '
    if is_written {}; then
        echo "File for SRR ID: {} already exists, skipping download." >> '$LOG_FILE'
    else
        echo "Downloading SRR ID: {}" >> '$LOG_FILE'
        fastq-dump --split-files {} -O '$OUTPUT_DIR' >> '$LOG_FILE' 2>&1
        echo "Written file for SRR ID: {}" >> '$LOG_FILE'
    fi
'

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"

# Check if the number of unique FASTQ base names matches the number of SRR IDs
# Count the number of unique FASTQ base names
UNIQUE_FASTQ_COUNT=$(ls $OUTPUT_DIR/*.fastq 2>/dev/null | xargs -n 1 basename | cut -d '_' -f 1 | cut -d '.' -f 1 | sort | uniq | wc -l)

if [ $UNIQUE_FASTQ_COUNT -ne $SRR_COUNT ]; then
    echo "Download failed at $(date): number of unique FASTQ files ($UNIQUE_FASTQ_COUNT) does not match number of SRR IDs ($SRR_COUNT)."  >> "$LOG_FILE"
    exit 1
else
    echo "srr_ids: $SRR_IDS" >> "$LOG_FILE"
    echo "Download successful: number of unique FASTQ files matches number of SRR IDs." >> "$LOG_FILE"
    echo "Job completed on $(hostname) at $(date)" >> "$LOG_FILE"
 
    sed_fastq_id() {
        local SRR_ID=$1
        local PREFIX=${SRR_ID:0:3}
        for suffix in 1 2; do
            sed '/^+${PREFIX}/s/\(^+\).*/\1/' "$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}.fastq" > "$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}_clean.fastq"
        done
    }

    export -f sed_fastq_id
    echo "$SRR_IDS" | tr ' ' '\n' | parallel -j $CPUS sed_fastq_id
fi



check_fastq_clean_lines() {
    local SRR_ID=$1
    local all_files_match=true

    for suffix in 1 2; do
        original_lines=$(wc -l < "$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}.fastq")
        clean_lines=$(wc -l < "$INPUT_FASTQ_DIR/${SRR_ID}_${suffix}_clean.fastq")
        
        if [[ $original_lines -ne $clean_lines ]]; then
            echo "Line count mismatch for ${SRR_ID}_${suffix}.fastq and ${SRR_ID}_${suffix}_clean.fastq" >> $LOG_FILE
            all_files_match=false
        fi
    done

    if $all_files_match; then
        echo "sed completed successfully for SRR ID: $SRR_ID" >> $LOG_FILE
        
        # Define JOB_SCRIPT variable to avoid using uninitialized variable
        JOB_SCRIPT="/proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/src/processing_metagenomics_tmp.sh"

        # Create a unique job script for each BioProject
        JOB_SCRIPT_TEMPLATE="/proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/src/processing_metagenomics.sh"
        cp "$JOB_SCRIPT_TEMPLATE" "$JOB_SCRIPT"

        # Replace placeholders in the job script with actual values
        sed -i "s|BIOPROJECT_PLACEHOLDER|$BIOPROJECT|g" "$JOB_SCRIPT"

        # Submit the job
        sbatch "$JOB_SCRIPT"
        echo "Submitted processing job for BioProject $BIOPROJECT." >> $LOG_FILE

        # Remove the job script after submission
        rm "$JOB_SCRIPT"
        return 0
    else
        echo "File validation failed for SRR ID: $SRR_ID. Job not submitted." >> $LOG_FILE
        return 1
    fi
}

export -f check_fastq_clean_lines
echo "$SRR_IDS" | tr ' ' '\n' | parallel -j $CPUS check_fastq_clean_lines







