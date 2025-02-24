#!/bin/bash

# Check if at least two arguments are provided: the script path and at least one BioProject ID
if [ $# -lt 2 ]; then
    echo "Usage: $0 <Script_Path> <BioProject_ID_1> [BioProject_ID_2 ... BioProject_ID_N]"
    exit 1
fi

# Extract the script path
SCRIPT_PATH=$1
shift  # Shift arguments so that $1 now refers to the first BioProject ID

# Check if the script path exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script file $SCRIPT_PATH not found."
    exit 1
fi

# Loop through all BioProject IDs provided as arguments
for BIOPROJECT_ID in "$@"; do

    # Define file paths for the current BioProject
    CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT_ID/0_metadata/${BIOPROJECT_ID}_runinfo.txt"
    HUMANN_SRC="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics"
    
    # Check if the CSV file exists for the current BioProject
    if [ ! -f "$CSV_FILE" ]; then
        echo "Error: CSV file $CSV_FILE not found for BioProject $BIOPROJECT_ID."
        continue  # Skip this BioProject and move to the next one
    fi

    # Extract SAMPLE_IDs and Library Layouts from the CSV file and save them to a temporary file
    awk -F, 'NR>1 {print $26, $16}' "$CSV_FILE" > sample_ids_and_layouts.txt

    # Split the file into smaller parts, each containing 10 lines (adjust based on your needs)
    split -l 10 sample_ids_and_layouts.txt batch_

    # Loop through the batch files and create SLURM scripts for each one
    for batch_file in batch_*; do
        # Create a new SLURM script for the batch
        output_script="slurm_${BIOPROJECT_ID}_${batch_file}.sh"
        
        # Copy the base SLURM template and replace placeholders
        cp "$SCRIPT_PATH" "$output_script"
        
        # Replace the placeholder for BioProject ID in the new SLURM script
        sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$output_script"
        
        # Replace the placeholder for batch filename in the new SLURM script
        sed -i "s/samples_and_layouts_batch/${batch_file}/" "$output_script"
        
        # Submit the job
        sbatch "$output_script"
    done

    # Clean up temporary batch files
    rm batch_*
    rm sample_ids_and_layouts.txt

done