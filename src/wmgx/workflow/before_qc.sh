#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J bakery_PRJNA526861
#SBATCH --partition=main
#SBATCH -t 10:00:00  # Keep 10 hours but allow auto-resubmission
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/log/%x_%A.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/log/%x_%A.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Define paths
BIOPROJECT="PRJNA526861"
metadata_file="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
raw_data_dir="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw"

# Read the metadata file, skip the header, and process each line
tail -n +2 "$metadata_file" | while IFS=, read -r run rest; do
    # Extract the Library Strategy (12th column)
    library_strategy=$(echo "$rest" | awk -F',' '{print $12}' | tr -d '"')

    # Define the target base directory based on the Library Strategy
    target_base_dir="$raw_data_dir/$library_strategy"

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

echo "✅ Files have been organized into directories by Library Strategy and run ID."

#!/bin/bash

# Define the parent directory containing the folders
PARENT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS"

# Define the target directory where files will be moved back
TARGET_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw"

# Move into the parent directory
cd "$PARENT_DIR" || exit

# Loop through all subdirectories in the parent directory
for dir in */; do
    # Move all `.fastq.gz` files from the subdirectory to the target directory
    mv "$dir"*.fastq.gz "$TARGET_DIR/" 2>/dev/null
    echo "Moved files from $dir to $TARGET_DIR"
done

# Print completion message
echo "✅ All files have been moved back to $TARGET_DIR"



# Define paths
metadata_file="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
raw_data_dir="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw"

# Read the metadata file, skip the header, and process each line
tail -n +2 "$metadata_file" | while IFS=, read -r run rest; do
    # Extract the Library Strategy (11th column)
    library_strategy=$(echo "$rest" | awk -F',' '{print $12}' | tr -d '"')

    # Define the target directory based on the Library Strategy
    target_dir="$raw_data_dir/$library_strategy"

    # Create the directory if it does not exist
    mkdir -p "$target_dir"

    # Check for multiple FASTQ file formats and move them
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


# Define the input directory containing the fastq.gz files
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS"

# Define the output directory for cleaned files
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS_sed"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through each fastq.gz file in the input directory
for INPUT_FILE in "$INPUT_DIR"/*.fastq.gz; do
    # Extract the file name (without path)
    FILENAME=$(basename "$INPUT_FILE")
    
    # Define the output file path
    OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

    # Process the file: transform the '+' line in the fastq.gz file
    zcat "$INPUT_FILE" | awk 'NR%4==3 {print "+"} NR%4!=3' | gzip > "$OUTPUT_FILE"

    # Print a status message
    echo "Processed $INPUT_FILE -> $OUTPUT_FILE"
done


#!/bin/bash

# Define the directory containing the .fastq.gz files
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/1_1_raw/WGS_awk"

# Loop through each .fastq.gz file in the directory
for file in "$INPUT_DIR"/*.fastq.gz; do
    # Extract the run column (filename without the extension)
    run_id=$(basename "$file" .fastq.gz)
    
    # Create a folder named after the run column
    target_dir="$INPUT_DIR/$run_id"
    mkdir -p "$target_dir"
    
    # Move the .fastq.gz file into the folder
    mv "$file" "$target_dir/"
    
    # Print a status message
    echo "Moved $file to $target_dir/"
done

echo "✅ All files have been organized into their respective run column folders."



BIOPROJECT="PRJNA526861"
metadata_file="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
raw_data_dir="/cfs/klemming/home/x/xueyaw/xueyao/tmp"
tail -n +2 "$metadata_file" | while IFS=, read -r run rest; do
    # Extract the Library Strategy (12th column)
    library_strategy=$(echo "$rest" | awk -F',' '{print $12}' | tr -d '"')

    # Define the target base directory based on the Library Strategy
    target_base_dir="$raw_data_dir/$library_strategy"

    # Define the final target directory based on the run ID
    target_dir="$target_base_dir/$run"

    # Create the directory for the run ID if it doesn't already exist
    mkdir -p "$target_dir"


done





#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J awk_parallel
#SBATCH --partition=main
#SBATCH -t 6:00:00 
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Load Conda environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Define paths
BIOPROJECT="PRJNA731589"
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS_awk"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Export required variables for GNU Parallel
export OUTPUT_DIR

# Function to process a single file
process_file() {
    INPUT_FILE=$1
    SAMPLE_ID=$(basename "$(dirname "$INPUT_FILE")")  # Extract sample ID (parent folder name)
    
    # Define sample output directory
    SAMPLE_OUTPUT_DIR="$OUTPUT_DIR/$SAMPLE_ID"
    mkdir -p "$SAMPLE_OUTPUT_DIR"

    # Define output file path
    OUTPUT_FILE="$SAMPLE_OUTPUT_DIR/$(basename "$INPUT_FILE")"

    # Process the file: transform the '+' line in the fastq.gz file
    zcat "$INPUT_FILE" | awk 'NR%4==3 {print "+"} NR%4!=3' | gzip > "$OUTPUT_FILE"

    # Print a status message
    echo "Processed $INPUT_FILE -> $OUTPUT_FILE"
}

export -f process_file

# Use GNU Parallel to process files in parallel, searching in each sample_id directory
find "$INPUT_DIR" -mindepth 2 -name "*.fastq.gz" | parallel -j $SLURM_CPUS_PER_TASK process_file {}

echo "✅ All files have been processed."













