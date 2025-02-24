#!/bin/bash



# Load Conda environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Project directories
#BIOPROJECT="PRJNA731589"
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/git_repo/biobakery_workflows/examples/wmgx/paired"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/git_repo/biobakery_workflows/examples/output2"
DATABASE_DIR="/cfs/klemming/home/x/xueyaw/xueyao/biobakery_workflows_databases"

#LOG_FILE="$LOG_DIR/bakery_PRJNA526861_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"


# Run bioBakery Workflow for this sample
biobakery_workflows wmgx --input "$INPUT_DIR" --output "$OUTPUT_DIR" \
    --contaminate-databases "$DATABASE_DIR/kneaddata_db_human_genome,$DATABASE_DIR/kneaddata_db_human_metatranscriptome,$DATABASE_DIR/kneaddata_db_rrna" \
    --threads 4 \
    --bypass-strain-profiling \
    --remove-intermediate-output \
    --functional-profiling-options "--pathways unipathway"
    --qc-options "--run-fastqc-start --run-fastqc-end" \


