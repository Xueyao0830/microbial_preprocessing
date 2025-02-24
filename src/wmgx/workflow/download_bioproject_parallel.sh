#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J download_PRJNA731589
#SBATCH --partition=main
#SBATCH -t 4:00:00  # Keep 10 hours but allow auto-resubmission
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --array=1-173
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Redirect all stdout and stderr to the log file
exec > >(tee -a /home/xueyao/hdd_xueyao/data/wgs/PRJNA731589/1_1_raw_download.log) 2>&1

# Source bashrc to ensure all environment variables are loaded
#source ~/.bashrc

# Set environment variables
#export PATH=$PATH:/home/xueyao/bin/sratoolkit.3.1.1-ubuntu64/bin
#export PATH=$PATH:/home/xueyao/bin/seqtk
#export PATH=$PATH:/home/xueyao/bin/edirect

# Define variables
BIOPROJECT="PRJNA731589"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw"
OUTPUT_METADATA_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata"
LOG_FILE="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw_download.log"
  # Use single CPU to control download rate
#MIN_FREE_SPACE_GB=10  # Minimum free space threshold in GB
metadata_file="$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt"
#raw_data_dir="$OUTPUT_DIR/$BIOPROJECT/1_1_raw"

# Log start time
start_time=$(date +%s)  >> "$LOG_FILE"
echo "Job started on $(hostname) at $(date)"   >> "$LOG_FILE"
echo "Downloading raw FASTQ files for BioProject: $BIOPROJECT"   >> "$LOG_FILE"
echo "Output directory: $OUTPUT_DIR"   >> "$LOG_FILE"

# Create directories and log file
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_METADATA_DIR"
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"


# Fetch run info using esearch and efetch, extract SRR IDs, Library Strategy, and Layout
esearch -db sra -query $BIOPROJECT | efetch -format runinfo > $OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt
SRR_IDS_AND_LibraryStrategy_AND_LAYOUT=$(awk -F, 'NR>1 {print $1, $13, $16}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt")

# Extract already downloaded SRR IDs from the log file
WRITTEN_SRRS=$(grep "Written file for SRR ID:" "$LOG_FILE" | awk '{print $NF}' | sort | uniq)

# Function to check if an SRR ID has been downloaded
is_written() {
    local srr_id=$1
    echo "$WRITTEN_SRRS" | grep -q "$srr_id"
}

# Export the function so it can be used with parallel
export -f is_written

# Function to process and download SRR IDs
fastq_dump() {
    local SRR_ID=$1
    local LAYOUT=$2
    local LibraryStrategy=$3
    local BIOPROJECT="PRJNA731589"
    local OUTPUT_DIR="/home/xueyao/hdd_xueyao/data/wgs/$BIOPROJECT/1_1_raw"
    local OUTPUT_METADATA_DIR="/home/xueyao/hdd_xueyao/data/wgs/$BIOPROJECT/0_metadata"
    local LOG_FILE="/home/xueyao/hdd_xueyao/data/wgs/$BIOPROJECT/1_1_raw_download.log"

    # Skip if the SRR ID has already been downloaded
    if is_written "$SRR_ID"; then
        echo "Skipping already downloaded SRR ID: $SRR_ID" >> "$LOG_FILE"
        return
    fi

    echo "Downloading $LAYOUT SRR ID: $SRR_ID" >> "$LOG_FILE"

    if [ "$LAYOUT" == "PAIRED" ]; then
        # Paired-end data
        fastq-dump --split-files --gzip -O "$OUTPUT_DIR" "$SRR_ID" >> "$LOG_FILE" 2>&1
    else
        # Single-end data
        fastq-dump --gzip -O "$OUTPUT_DIR" "$SRR_ID" >> "$LOG_FILE" 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo "Written file for SRR ID: $SRR_ID" >> "$LOG_FILE"
    else
        echo "Failed to download SRR ID: $SRR_ID" >> "$LOG_FILE"
    fi
}
# Export the fastq_dump function to use with parallel
export -f fastq_dump

# Run parallel download, skipping already downloaded files
echo "$SRR_IDS_AND_LibraryStrategy_AND_LAYOUT" | \
parallel -j $CPUS --colsep ' ' fastq_dump {1} {3} {2}

# Verify if all files have been successfully downloaded
echo "Verifying if all files have been downloaded..." >> "$LOG_FILE"
all_successful=true  # Assume all are successful unless a failure is found
for SRR in $(awk -F, 'NR>1 {print $1}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt"); do
    if ! is_written "$SRR"; then
        echo "ERROR: File for SRR ID: $SRR missing" >> "$LOG_FILE"
        all_successful=false
    else
        echo "SRR ID: $SRR successfully downloaded." >> "$LOG_FILE"
    fi
done

# Check if all were successful
if [ "$all_successful" = true ]; then
    echo "All files successfully downloaded!" >> "$LOG_FILE"
    echo "All successful"
else
    echo "Some files were missing." >> "$LOG_FILE"
fi



# Log end time and calculate runtime
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"