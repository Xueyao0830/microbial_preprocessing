#!/bin/bash

# Check if at least two arguments are provided: the script path and at least one BioProject ID
if [ $# -lt 2 ]; then
    echo "Usage: $0 <Script_Path> <BioProject_ID_1> [BioProject_ID_2 ... BioProject_ID_N]"
    exit 1
fi

SCRIPT_PATH=$1
shift  # Shift arguments so that $1 now refers to the first BioProject ID

# Check if the script path exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script file $SCRIPT_PATH not found."
    exit 1
fi

for BIOPROJECT_ID in "$@"; do
    TEMP_SCRIPT_PATH="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/temp_${BIOPROJECT_ID}_download.sh"

    # Substitute "SUBSTITUTION_BIO_ID" with the provided BioProject ID in the script
    sed "s/SUBSTITUTION_BIO_ID/${BIOPROJECT_ID}/g" $SCRIPT_PATH > $TEMP_SCRIPT_PATH

    # Submit the modified script using sbatch
    sbatch $TEMP_SCRIPT_PATH
    rm $TEMP_SCRIPT_PATH

    # Optionally, remove the temporary script after submission (uncomment the line below if desired)
    # rm $TEMP_SCRIPT_PATH
done