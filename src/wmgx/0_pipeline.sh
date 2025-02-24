#!/bin/bash

# Check if at least one BioProject ID is provided as a command line argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <BioProject_ID_1> [BioProject_ID_2 ... BioProject_ID_N]"
    exit 1
fi

# Define script file names
SCRIPT_1="1_1_download_bioproject_parallel.sh"
SCRIPT_2="2_kneaddata_parallel.sh"
SCRIPT_6="3_1_merge_sample_kneaddata.sh"
SCRIPT_3="3_metaphlan_parallel.sh"
SCRIPT_4="4_humann_parallel.sh"
SCRIPT_5="1_2_sed_wgs.sh"

ORIGINAL_FOLDER="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics"

# Loop over each BioProject ID provided as an argument
for BIOPROJECT_ID in "$@"; do
    BIOPROJECT_ID_FOLDER="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/bioproject_pipeline/$BIOPROJECT_ID"

    # Create a new directory for the BioProject
    mkdir -p "$BIOPROJECT_ID_FOLDER"

    # Copy the scripts into the new directory
    cp "$ORIGINAL_FOLDER/$SCRIPT_1" "$BIOPROJECT_ID_FOLDER"
    cp "$ORIGINAL_FOLDER/$SCRIPT_2" "$BIOPROJECT_ID_FOLDER"
    cp "$ORIGINAL_FOLDER/$SCRIPT_3" "$BIOPROJECT_ID_FOLDER"
    cp "$ORIGINAL_FOLDER/$SCRIPT_4" "$BIOPROJECT_ID_FOLDER"
    cp "$ORIGINAL_FOLDER/$SCRIPT_5" "$BIOPROJECT_ID_FOLDER"
    cp "$ORIGINAL_FOLDER/$SCRIPT_6" "$BIOPROJECT_ID_FOLDER"

    # Perform the substitution of the BioProject ID in the copied scripts
    sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$BIOPROJECT_ID_FOLDER/$SCRIPT_1"
    sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$BIOPROJECT_ID_FOLDER/$SCRIPT_2"
    sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$BIOPROJECT_ID_FOLDER/$SCRIPT_3"
    sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$BIOPROJECT_ID_FOLDER/$SCRIPT_4"
    sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$BIOPROJECT_ID_FOLDER/$SCRIPT_5"
    sed -i "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" "$BIOPROJECT_ID_FOLDER/$SCRIPT_6"

    # Optionally, you can run the first script here if needed
    #echo "Running $SCRIPT_1 for BioProject $BIOPROJECT_ID..."
    #sbatch "$BIOPROJECT_ID_FOLDER/$SCRIPT_1"

done