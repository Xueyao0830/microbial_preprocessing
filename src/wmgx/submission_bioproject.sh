#!/bin/bash
#

# Load necessary modules
module load parallel/20181122-nsc1  # Load GNU parallel


# Define variables
DATA_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/data/database"
WORK_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/rawdata/metagenomics"



JOB_SCRIPT_TEMPLATE="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/rawdata/metagenomics/download_fastq_bioproject.sh"  # Template script for individual jobs

# Loop over each biosample
BIOPROJECT_FILE="$DATA_DIR/ena_id.csv"  # CSV file with BioProject IDs


# Read BioProject IDs from the CSV file and submit a job for each
while IFS=, read -r BIOPROJECT; do
    if [[ -z "$BIOPROJECT" ]]; then
        continue  # Skip empty lines
    fi

    echo "Processing BioProject $BIOPROJECT"

    # Create a unique job script for each BioProject
    JOB_SCRIPT="$WORK_DIR/${BIOPROJECT}.sh"
    cp "$JOB_SCRIPT_TEMPLATE" "$JOB_SCRIPT"

    # Replace placeholders in the job script with actual values
    sed -i "s|BIOPROJECT_PLACEHOLDER|$BIOPROJECT|g" "$JOB_SCRIPT"

    LOG_DIR="/proj/naiss2024-6-169/users/x_xwang/project/microbio_metabolite_network/log/download/$BIOPROJECT"

    mkdir -p "$LOG_DIR"

    # Submit the job
    sbatch "$JOB_SCRIPT"
    echo "Submitted job for BioProject $BIOPROJECT."

    # Remove the job script after submission
    rm "$JOB_SCRIPT"

done < "$BIOPROJECT_FILE"

echo "All jobs submitted."

