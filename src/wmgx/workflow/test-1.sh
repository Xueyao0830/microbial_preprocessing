#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J download_PRJNA731589
#SBATCH --partition=main
#SBATCH -t 23:30:00  # 4 hours, adjust if needed
#SBATCH --cpus-per-task=32
#SBATCH --mem=512G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Load environment
#source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
#conda activate biobakery_env

# Define variables
BIOPROJECT="PRJNA731589"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS"
OUTPUT_METADATA_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata"
LOG_FILE="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw_download_test.log"

# Number of parallel jobs
CPUS=32

# Create directories
mkdir -p "$OUTPUT_DIR" "$OUTPUT_METADATA_DIR"
touch "$LOG_FILE"

# Log start time
start_time=$(date +%s)
echo "📥 Job started on $(hostname) at $(date)" | tee -a "$LOG_FILE"
echo "Downloading FASTQ files for BioProject: $BIOPROJECT" | tee -a "$LOG_FILE"
echo "Output directory: $OUTPUT_DIR" | tee -a "$LOG_FILE"

# Fetch metadata if not already available
if [ ! -f "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt" ]; then
    echo "📑 Fetching metadata for $BIOPROJECT..." | tee -a "$LOG_FILE"
    esearch -db sra -query $BIOPROJECT | efetch -format runinfo > "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt"
fi

# Extract SRR IDs, Library Strategy, and Layout
SRR_IDS_AND_LibraryStrategy_AND_LAYOUT=$(awk -F, 'NR>1 {print $1, $13, $16}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt")

# Extract already downloaded SRR IDs
WRITTEN_SRRS=$(grep "Written file for SRR ID: " "$LOG_FILE" | awk '{print $NF}' | sort | uniq)

# Function to check if an SRR ID has been downloaded
is_written() {
    local srr_id=$1
    echo "$WRITTEN_SRRS" | grep -qw "$srr_id"
}

# Function to process and download SRR IDs
#fastq_dump() {
#    local SRR_ID=$1
#    local LAYOUT=$2
#    local LibraryStrategy=$3
#    local BIOPROJECT="PRJNA731589"
#    local OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw"
#    local OUTPUT_METADATA_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata"
#    local LOG_FILE="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw_download.log"
#
#    echo "🚀 Downloading $LAYOUT SRR ID: $SRR_ID" | tee -a "$LOG_FILE"
#
#    if [ "$LAYOUT" == "PAIRED" ]; then
#        fastq-dump --split-files --gzip -O "$OUTPUT_DIR" "$SRR_ID" >> "$LOG_FILE" 2>&1
#    else
#        fastq-dump --gzip -O "$OUTPUT_DIR" "$SRR_ID" >> "$LOG_FILE" 2>&1
#    fi
#
#    # Verify successful download
#    if [ $? -eq 0 ]; then
#        echo "✅ Written file for SRR ID: $SRR_ID" | tee -a "$LOG_FILE"
#    else
#        echo "❌ Failed to download SRR ID: $SRR_ID" | tee -a "$LOG_FILE"
#    fi
#}
#
## Export function for parallel execution
#export -f fastq_dump
export -f is_written

# Ensure parallel is available
if ! command -v parallel &> /dev/null; then
    echo "❌ GNU Parallel not found! Running in serial mode." | tee -a "$LOG_FILE"
    for entry in $SRR_IDS_AND_LibraryStrategy_AND_LAYOUT; do
        fastq_dump $entry
    done
else
    # Run parallel download
    echo "$SRR_IDS_AND_LibraryStrategy_AND_LAYOUT" | \
    parallel -j $CPUS --colsep ' ' fastq_dump {1} {3} {2}
fi

# Verify if all files were downloaded
echo "🔍 Verifying downloaded files..." | tee -a "$LOG_FILE"
all_successful=true  # Assume all are successful unless a failure is found

for SRR in $(awk -F, 'NR>1 {print $1}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt"); do
    if ! is_written "$SRR"; then
        echo "❌ ERROR: Missing file for SRR ID: $SRR" | tee -a "$LOG_FILE"
        all_successful=false
    else
        echo "✅ SRR ID: $SRR successfully downloaded." | tee -a "$LOG_FILE"
    fi
done

# Final check
if [ "$all_successful" = true ]; then
    echo "🎉 All files successfully downloaded!" | tee -a "$LOG_FILE"
else
    echo "⚠️ Some files were missing." | tee -a "$LOG_FILE"
fi

# Log end time
end_time=$(date +%s)
runtime=$((end_time - start_time))
echo "⏳ Job ended at: $(date) | Total runtime: $runtime seconds" | tee -a "$LOG_FILE"
