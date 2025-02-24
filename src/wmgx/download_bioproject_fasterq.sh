#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J d_SUBSTITUTION_BIO_ID
#SBATCH -t 30:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/data/metagenomics/SUBSTITUTION_BIO_ID/download.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/data/metagenomics/SUBSTITUTION_BIO_ID/download.err

source ~/.bashrc
conda activate mm_crc
# Load the required module
module load parallel/20181122-nsc1

# Set the environment variables
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/sratoolkit.3.1.1-ubuntu64/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/seqtk
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/edirect

# Define variables
BIOPROJECT="SUBSTITUTION_BIO_ID"
CPUS=20  # Number of CPUs to use
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
OUTPUT_METADATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT"
LOG_FILE="$OUTPUT_DIR/download.log"

# Create directories and log file
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_METADATA_DIR"
touch "$LOG_FILE"

# Log start time
echo "Job started on $(hostname) at $(date)" >> "$LOG_FILE"
echo "Downloading FASTQ files for BioProject: $BIOPROJECT" >> "$LOG_FILE"
echo "Output directory: $OUTPUT_DIR" >> "$LOG_FILE"

# Fetch run info using esearch and efetch, extract SRR IDs, Library Strategy, and Layout
esearch -db sra -query $BIOPROJECT | efetch -format runinfo > $OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt

# Properly extract the SRR IDs, Library Strategy, and Layout
SRR_IDS_AND_LibraryStrategy_AND_LAYOUT=$(awk -F, 'NR>1 {print $1 " " $13 " " $16}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt")

# Extract already written SRR IDs from the log file
if [ -f "$LOG_FILE" ]; then
    WRITTEN_SRRS=$(grep "Written file for SRR ID:" "$LOG_FILE" | sed 's/^.*SRR ID: \(.*\)/\1/' | sort | uniq)
else
    WRITTEN_SRRS=""
fi

# Function to check if an SRR ID is already written
is_written() {
    local srr_id=$1
    echo "$WRITTEN_SRRS" | grep -q "$srr_id"
}

# Process each SRR ID
while IFS=' ' read -r SRR_ID LibraryStrategy LAYOUT; do
    if is_written "$SRR_ID"; then
        echo "File for SRR ID: $SRR_ID already exists, skipping download." >> "$LOG_FILE"
        continue
    fi

    echo "Downloading $LAYOUT SRR ID: $SRR_ID" >> "$LOG_FILE"

    if [ "$LAYOUT" == "PAIRED" ]; then
        # Paired-end data
        fasterq-dump -e $CPUS -O "$OUTPUT_DIR" "$SRR_ID" >> "$LOG_FILE" 2>& 1
        if [ $? -eq 0 ]; then
            pigz -p $CPUS "${OUTPUT_DIR}/${SRR_ID}_1.fastq"
            pigz -p $CPUS "${OUTPUT_DIR}/${SRR_ID}_2.fastq"
            mv "${OUTPUT_DIR}/${SRR_ID}_1.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_1_${LibraryStrategy}.fastq.gz"
            mv "${OUTPUT_DIR}/${SRR_ID}_2.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_2_${LibraryStrategy}.fastq.gz"
            echo "Written file for SRR ID: $SRR_ID" >> "$LOG_FILE"
        else
            echo "Failed to download SRR ID: $SRR_ID" >> "$LOG_FILE"
        fi
    else
        # Single-end data
        fasterq-dump -e $CPUS -O "$OUTPUT_DIR" "$SRR_ID" >> "$LOG_FILE" 2>& 1
        if [ $? -eq 0 ]; then
            pigz -p $CPUS "${OUTPUT_DIR}/${SRR_ID}.fastq"
            mv "${OUTPUT_DIR}/${SRR_ID}.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_0_${LibraryStrategy}.fastq.gz"
            echo "Written file for SRR ID: $SRR_ID" >> "$LOG_FILE"
        else
            echo "Failed to download SRR ID: $SRR_ID" >> "$LOG_FILE"
        fi
    fi
done <<< "$SRR_IDS_AND_LibraryStrategy_AND_LAYOUT"


# Define function for sed processing of fastq files
sed_fastq_id() {
    for file in "$OUTPUT_DIR"/*_WGS.fastq.gz; do
        local filename=$(basename "$file")
        local SRR_ID=$(echo "$filename" | cut -d '_' -f 1)
        local suffix=$(echo "$filename" | cut -d '_' -f 2)
        local PREFIX=${SRR_ID:0:3}

        pigz -dc "$file" | \
        sed "/^+${PREFIX}/s/\(^+\).*/\1/" | \
        pigz -p $CPUS > "$OUTPUT_DIR/${SRR_ID}_${suffix}_clean_final.fastq.gz"
    done
}

# Define function for checking line counts
check_fastq_clean_lines() {
    local all_files_match=true

    for SRR_ID in $(echo "$SRR_IDS_AND_LibraryStrategy_AND_LAYOUT" | cut -d ',' -f 1); do
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
        for SRR_ID in $(echo "$SRR_IDS_AND_LibraryStrategy_AND_LAYOUT" | cut -d ',' -f 1); do
            for suffix in 0 1 2; do
                rm "$OUTPUT_DIR/${SRR_ID}_${suffix}_WGS.fastq.gz"
            done
        done
    else
        echo "Some files did not match, original files were not deleted." >> $LOG_FILE
    fi
}

# Run sed_fastq_id on each SRR_ID
sed_fastq_id

# Check if all files are processed correctly
check_fastq_clean_lines



# Log end time and calculate runtime
end_time=$(date +%s)
echo "Job ended at: $(date)" >> "$LOG_FILE"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds" >> "$LOG_FILE"