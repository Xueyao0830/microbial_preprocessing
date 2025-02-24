#!/bin/bash

BIOPROJECT="PRJNA731589"
metadata_file="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
raw_data_dir="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw"


# Read the metadata file, skip the header, and process each line
tail -n +2 "$metadata_file" | while IFS=, read -r run rest; do
    # Extract the Library Strategy (12th column)
    library_strategy=$(echo "$rest" | awk -F',' '{print $12}' | tr -d '"')

    # Define the target base directory based on the Library Strategy
    target_base_dir="$raw_data_dir/$library_strategy"

    mkdir -p $target_base_dir

    # Define the final target directory based on the run ID
    target_dir="$target_base_dir/$run"

    # Create the directory for the run ID if it doesn't already exist
    mkdir -p "$target_dir"

    # Check for multiple FASTQ file formats and move them into the run's directory
    for ext in ".fastq.gz" ".fq.gz" "_1.fastq.gz" "_2.fastq.gz"; do
        fastq_file="${raw_data_dir}/${run}${ext}"
        if [[ -f "$fastq_file" ]]; then
            mv "$fastq_file" "$target_dir/"
            echo "Moved $fastq_file to $target_dir"
        else
            echo "Warning: $fastq_file not found, skipping..."
        fi
    done
done




