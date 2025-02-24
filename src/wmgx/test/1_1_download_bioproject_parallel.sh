#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J 731589_download
#SBATCH -t 20:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/PRJNA731589_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/PRJNA731589_%j.err

module load parallel/20181122-nsc1
conda activate /proj/naiss2024-6-169/users/x_xwang/.conda/envs/mm_crc

export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/sratoolkit.3.1.1-ubuntu64/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/seqtk
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/edirect

# Update with your output directory path
BIOPROJECT="PRJEB67450"

CPUS=20  # Number of CPUs to use

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

# Fetch run info using esearch and efetch, extract SRR IDs and Library Strategy
esearch -db sra -query $BIOPROJECT | efetch -format runinfo > $OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt
SRR_IDS_AND_LibraryStrategy_AND_LAYOUT=$(awk -F, 'NR>1 {print $1, $13, $16}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt")

# Extract already written SRR IDs from the log file
if [ -f "$LOG_FILE" ]; then
    WRITTEN_SRRS=$(grep "Written file for SRR ID:" "$LOG_FILE" | sed 's/^.*SRR ID: //' | sort | uniq)
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

fastq_dump() {
    local SRR_ID=$1
    local LAYOUT=$2
    local LibraryStrategy=$3
    local BIOPROJECT="PRJNA731589"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
    local LOG_FILE="$OUTPUT_DIR/download.log"

    if is_written "$SRR_ID"; then
        echo "File for SRR ID: $SRR_ID already exists, skipping download." >> "$LOG_FILE"
    else
        echo "Downloading SRR ID: $SRR_ID" >> "$LOG_FILE"
        fastq-dump --split-files --gzip $SRR_ID -O "$OUTPUT_DIR" >> "$LOG_FILE" 2>&1
        if [[ -f "${OUTPUT_DIR}/${SRR_ID}_1.fastq.gz" && -f "${OUTPUT_DIR}/${SRR_ID}_2.fastq.gz" ]]; then
            mv "${OUTPUT_DIR}/${SRR_ID}_1.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_1_${LibraryStrategy}.fastq.gz"
            mv "${OUTPUT_DIR}/${SRR_ID}_2.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_2_${LibraryStrategy}.fastq.gz"
        else
            mv "${OUTPUT_DIR}/${SRR_ID}.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_0_${LibraryStrategy}.fastq.gz"
        fi
        echo "Written file for SRR ID: $SRR_ID" >> "$LOG_FILE"
    fi
}

export -f fastq_dump

# Download and process the files
echo "$SRR_IDS_AND_LibraryStrategy" | parallel -j $CPUS --colsep ',' fastq_dump {1} {2} {3}

# Check if the number of unique FASTQ base names matches the number of SRR IDs
UNIQUE_FASTQ_COUNT=$(ls $OUTPUT_DIR/*.fastq.gz 2>/dev/null | xargs -n 1 basename | cut -d '_' -f 1 | cut -d '.' -f 1 | sort | uniq | wc -l)
SRR_COUNT=$(echo "$SRR_IDS_AND_LibraryStrategy" | wc -l)

if [ $UNIQUE_FASTQ_COUNT -ne $SRR_COUNT ]; then
    echo "Download failed at $(date): number of unique FASTQ files ($UNIQUE_FASTQ_COUNT) does not match number of SRR IDs ($SRR_COUNT)." >> "$LOG_FILE"
    exit 1
else
    echo "All downloads are successful and files are renamed properly." >> "$LOG_FILE"
    echo "Job completed on $(hostname) at $(date)" >> "$LOG_FILE"
fi

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"