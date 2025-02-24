#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J sed_SUBSTITUTION_BIO_ID
#SBATCH -t 10:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=200G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/1_2_sed.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/1_2_sed.err

module load parallel/20181122-nsc1

# Define variables
BIOPROJECT="SUBSTITUTION_BIO_ID"


INPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_1_raw"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"
OUTPUT_METADATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata"
CPUS=20  # Number of CPUs to use

echo "Job started on $(hostname) at $(date)"
echo "sed wgs FASTQ files for BioProject: $BIOPROJECT"
echo "Output directory: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_METADATA_DIR"

# Fetch run info using esearch and efetch, extract SRR IDs and Library Strategy

SRR_IDS_AND_LibraryStrategy_AND_LAYOUT=$(awk -F, 'NR>1 {print $1, $13, $16}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt")

#1. change the raw into wgs or amp
LibraryStrategy_dump() {
      local SRR_ID=$1
      local LAYOUT=$2
      local LibraryStrategy=$3
      local BIOPROJECT="SUBSTITUTION_BIO_ID"
      local INPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_1_raw"
      local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"
      local PREFIX=${SRR_ID:0:3}
      local CPUS=20

    echo "Processing $LAYOUT ${LibraryStrategy} SRR ID: $SRR_ID"

    if [ "$LAYOUT" == "PAIRED" ]; then
        # Paired-end data
        rsync -a --progress "${INPUT_DIR}/${SRR_ID}_1.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_1_${LibraryStrategy}.fastq.gz"
        rsync -a --progress "${INPUT_DIR}/${SRR_ID}_2.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_2_${LibraryStrategy}.fastq.gz"

        for suffix in 1 2; do
            pigz -dc "$OUTPUT_DIR/${SRR_ID}_${suffix}_${LibraryStrategy}.fastq.gz" | \
            sed "/^+${PREFIX}/s/\(^+\).*/\1/" | \
            pigz -p $CPUS > "$OUTPUT_DIR/${SRR_ID}_${suffix}_${LibraryStrategy}_clean_final.fastq.gz"
            rm -r "$OUTPUT_DIR/${SRR_ID}_${suffix}_${LibraryStrategy}.fastq.gz"
            
        done
    else
        # Single-end data
        rsync -a --progress "${INPUT_DIR}/${SRR_ID}.fastq.gz" "${OUTPUT_DIR}/${SRR_ID}_0_${LibraryStrategy}.fastq.gz"
        pigz -dc "$OUTPUT_DIR/${SRR_ID}_0_${LibraryStrategy}.fastq.gz" | \
        sed "/^+${PREFIX}/s/\(^+\).*/\1/" | \
        pigz -p $CPUS > "$OUTPUT_DIR/${SRR_ID}_0_${LibraryStrategy}_clean_final.fastq.gz"
        rm "$OUTPUT_DIR/${SRR_ID}_0_${LibraryStrategy}.fastq.gz"
    fi
}

# Export the fastq_dump function to use with parallel
export -f LibraryStrategy_dump

# Run the parallel download
echo "$SRR_IDS_AND_LibraryStrategy_AND_LAYOUT" | \

parallel -j $CPUS --colsep ' ' LibraryStrategy_dump {1} {3} {2}

# Define function for checking line counts
check_fastq_clean_lines() {
      local all_files_match=true
      local BIOPROJECT="SUBSTITUTION_BIO_ID"
      local INPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_1_raw"
      local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"

    for SRR_ID in $(awk -F, 'NR>1 {print $1}' "$OUTPUT_METADATA_DIR/${BIOPROJECT}_runinfo.txt"); do
        for suffix in 0 1 2; do
            original_file="$INPUT_DIR/${SRR_ID}_${suffix}.fastq.gz"
            clean_file="$OUTPUT_DIR/${SRR_ID}_${suffix}_*clean_final.fastq.gz"

            if [ -f "$original_file" ] && [ -f "$clean_file" ]; then
                # Count lines in the original and cleaned files
                original_lines=$(zcat "$original_file" | wc -l)
                clean_lines=$(zcat "$clean_file" | wc -l)

                if [[ $original_lines -ne $clean_lines ]]; then
                    echo "Line count mismatch for $original_file and $clean_file"
                    all_files_match=false
                fi
            fi
        done
    done

    if [ "$all_files_match" = true ]; then
        echo "All files processed successfully!"
        rm -r $INPUT_DIR/*
    else
        echo "Some files have mismatched line counts."
    fi
}


# Check if all files are processed correctly
check_fastq_clean_lines

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"
echo "Sed processing is successfully done."










