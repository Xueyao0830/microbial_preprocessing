#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J bakery_PRJNA526861
#SBATCH --partition=main
#SBATCH -t 10:00:00  # Keep 10 hours but allow auto-resubmission
#SBATCH --cpus-per-task=64
#SBATCH --mem=256G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/log/%x_%A.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/log/%x_%A.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Load Conda environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh

conda activate biobakery_env

# Project directories
BIOPROJECT="PRJNA526861"
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS_awk"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output"
DATABASE_DIR="/cfs/klemming/home/x/xueyaw/xueyao/biobakery_workflows_databases"



# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
# Check if job is already completed
if [ -f "$OUTPUT_DIR/completion_flag.txt" ]; then
    echo "✅ Workflow is already completed. Exiting..."
    exit 0
fi

# Run bioBakery Workflow for this sample
biobakery_workflows wmgx --input "$INPUT_DIR/$SAMPLE_NAME" --output "$OUTPUT_DIR/$SAMPLE_NAME" \
    --contaminate-databases "$DATABASE_DIR/kneaddata_db_human_genome,$DATABASE_DIR/kneaddata_db_human_metatranscriptome,$DATABASE_DIR/kneaddata_db_rrna" \
    --threads 16 \
    #--local-jobs 10 \
    --bypass-strain-profiling \
    --remove-intermediate-output \
    --qc-options "--run-fastqc-start --run-fastqc-end --cat-final-output" \

# Check remaining time and resubmit if needed
TIME_LEFT=$(scontrol show job $SLURM_JOB_ID | grep -oP 'TimeLeft=\K[^ ]+')
MINUTES_LEFT=$(echo $TIME_LEFT | awk -F':' '{print $1*60 + $2}')

if [ "$MINUTES_LEFT" -lt 60 ]; then
    echo "⏳ Job is running out of time. Resubmitting..."
    sbatch $0
    exit 1
fi

# Mark workflow as completed
touch "$OUTPUT_DIR/completion_flag.txt"
echo "✅ Workflow completed successfully!"

