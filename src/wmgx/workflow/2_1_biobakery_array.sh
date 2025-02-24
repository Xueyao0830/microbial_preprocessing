#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J bakery_PRJNA731589
#SBATCH --partition=main
#SBATCH -t 20:00:00  # Keep 10 hours but allow auto-resubmission
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --array=0-171
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se


# Load Conda environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Project directories
BIOPROJECT="PRJNA731589"
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS_awk"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output_array"
DATABASE_DIR="/cfs/klemming/home/x/xueyaw/xueyao/biobakery_workflows_databases"

#LOG_FILE="$LOG_DIR/bakery_PRJNA526861_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Get the sample to process for this array job
SAMPLES=($(ls -1 "$INPUT_DIR"))
SAMPLE_NAME=${SAMPLES[$SLURM_ARRAY_TASK_ID]}

# Create sample-specific output directory
SAMPLE_OUTPUT_DIR="$OUTPUT_DIR/$SAMPLE_NAME"
mkdir -p "$SAMPLE_OUTPUT_DIR"

# Skip if the sample is already completed
if [ -f "$SAMPLE_OUTPUT_DIR/completion_flag.txt" ]; then
    echo "✅ Sample $SAMPLE_NAME is already completed. Skipping..."
    exit 0
fi

# Debugging: List input files
echo "📂 Input directory contents:"
ls -lh "$INPUT_DIR/$SAMPLE_NAME"

echo "🚀 Running bioBakery Workflow for sample: $SAMPLE_NAME..."

# Run bioBakery Workflow for this sample
biobakery_workflows wmgx --input "$INPUT_DIR/$SAMPLE_NAME" --output "$SAMPLE_OUTPUT_DIR" \
    --contaminate-databases "$DATABASE_DIR/kneaddata_db_human_genome,$DATABASE_DIR/kneaddata_db_human_metatranscriptome,$DATABASE_DIR/kneaddata_db_rrna" \
    --threads 16 \
    --bypass-strain-profiling \
    --remove-intermediate-output \
    --qc-options "--run-fastqc-start --run-fastqc-end" 


# Mark the sample as completed
# Check if the log file contains "INFO: AnADAMA run finished."
if grep -q "INFO: AnADAMA run finished." "$SAMPLE_OUTPUT_DIR/anadama.log"; then
    touch "$SAMPLE_OUTPUT_DIR/completion_flag.txt"
    echo "✅ Processing complete for sample: $SAMPLE_NAME"
else
    echo "❌ Processing failed for sample: $SAMPLE_NAME"
    exit 1
fi
