#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J resubmit_unfinished
#SBATCH --partition=main
#SBATCH -t 10:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --array=1-$(wc -l < remaining_samples.txt)
#SBATCH -o log/resubmit_%A_%a.log
#SBATCH -e log/resubmit_%A_%a.err

# Load environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Find unfinished samples
find "$OUTPUT_DIR" -type d -name "SAMPLE_NAME" | while read -r dir; do
    if [ ! -f "$dir/completion_flag.txt" ]; then
        basename "$dir" >> remaining_samples.txt
    fi
done

#SBATCH --array=1-$(wc -l < remaining_samples.txt)

# Read the sample name from the remaining samples file
SAMPLE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" remaining_samples.txt)



# Define directories
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output"

# Skip if already completed
if [ -f "$OUTPUT_DIR/$SAMPLE_NAME/completion_flag.txt" ]; then
    echo "✅ Sample $SAMPLE_NAME already completed. Skipping..."
    exit 0
fi

# Run bioBakery Workflow
biobakery_workflows wmgx --input "$INPUT_DIR/$SAMPLE_NAME" --output "$OUTPUT_DIR/$SAMPLE_NAME" \
    --threads 16 \
    --remove-intermediate-output
