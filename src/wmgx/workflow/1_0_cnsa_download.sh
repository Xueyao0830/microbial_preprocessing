#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J cnsa_parallel_download
#SBATCH --partition=main
#SBATCH -t 23:30:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=523G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/CNP0004314/log/%x_%A_%a.out
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/CNP0004314/log/%x_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env
# Define variables
DATA_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/CNP0004314"
BASE_URL="ftp://ftp.cngb.org/pub/CNSA/data5/CNP0004314"
LOG="$DATA_DIR/download.log"

# Create directories
mkdir -p "$DATA_DIR"
touch $LOG

# Generate file list if not already created
if [ ! -f files.txt ]; then
  echo "Fetching file list from server..."
  lftp "$BASE_URL" -e "cls -1 --recursive > files.txt; quit"
fi

# Filter only files (exclude directories)
grep -v '/$' files.txt > filtered_files.txt

# Download function
download_file() {
  local FILE="$1"
  lftp -e "set net:timeout 30; set net:max-retries 5; set net:reconnect-interval-base 5; \
           pget -n 8 -c \"$FILE\" -o \"$DATA_DIR/${FILE}\"; quit" "$BASE_URL"
}

export -f download_file
export DATA_DIR
export BASE_URL

# Run parallel downloads using SLURM CPUs
cat filtered_files.txt | parallel -j $SLURM_CPUS_PER_TASK download_file {}

echo "✅ All downloads completed."
