#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J test_process
#SBATCH -t 10:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/log/process/%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/log/process/%j.err

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist

# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC

BIOPROJECT="test_paired"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
CPUS=16 
# Extract SRR IDs from the input directory
SRR_IDS=$(ls $INPUT_FASTQ_DIR/*.fastq.gz | xargs -n 1 basename | cut -d '.' -f 1 | sort | uniq)

# Function to process single-end SRR ID
process_single_end_srr_id() {
    local SRR_ID=$1
    kneaddata --unpaired $INPUT_FASTQ_DIR/${SRR_ID}.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_index \
              --output $OUTPUT_DIR/kneaddataOutput/${SRR_ID} 
}

# Function to process paired-end SRR ID
process_paired_end_srr_id() {
    local SRR_ID=$1
    kneaddata --input1 $INPUT_FASTQ_DIR/${SRR_ID}_1.fastq.gz \
              --input2 $INPUT_FASTQ_DIR/${SRR_ID}_2.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_index \
              --output $OUTPUT_DIR/kneaddataOutput/${SRR_ID}
}

# Function to check and process SRR ID
# Function to check and process SRR ID
process_srr_id() {
    local SRR_ID=$1
    if [[ $SRR_ID == *_1 ]]; then
        local BASE_SRR_ID=${SRR_ID%_1}
        if [ -f ${INPUT_FASTQ_DIR}/${BASE_SRR_ID}_2.fastq.gz ]; then
            echo "Processing paired-end SRR ID: $BASE_SRR_ID"
            process_paired_end_srr_id $BASE_SRR_ID
        else
            echo "Processing single-end SRR ID: $SRR_ID"
            process_single_end_srr_id $SRR_ID
        fi
    else
        if [ -f ${INPUT_FASTQ_DIR}/${SRR_ID}_2.fastq.gz ]; then
            echo "Processing paired-end SRR ID: $SRR_ID"
            process_paired_end_srr_id $SRR_ID
        else
            echo "Processing single-end SRR ID: $SRR_ID"
            process_single_end_srr_id $SRR_ID
        fi
    fi
}

export -f process_single_end_srr_id
export -f process_paired_end_srr_id
export -f process_srr_id

# Run process_srr_id in parallel for each SRR_ID
for SRR_ID in $SRR_IDS; do
    process_srr_id $SRR_ID
done

FASTQC_OUTPUT_DIR="$OUTPUT_DIR/fastqc_kneaddata"
MULTIQC_OUTPUT_DIR="$OUTPUT_DIR/multiqc_output_kneaddata"

# Create output directories if they do not exist
mkdir -p $FASTQC_OUTPUT_DIR
mkdir -p $MULTIQC_OUTPUT_DIR

# Generate kneaddata read count table for all processed SRR IDs
for SRR_ID in $SRR_IDS; do
    kneaddata_read_count_table --input $OUTPUT_DIR/kneaddataOutput/${SRR_ID} --output $OUTPUT_DIR/kneaddataOutput/${SRR_ID}_kneaddata_read_count_table.tsv
    fastqc $OUTPUT_DIR/kneaddataOutput/${SRR_ID}/${SRR_ID}_kneaddata.fastq -o $FASTQC_OUTPUT_DIR
done

# Run FastQC on all processed files

#fastqc $OUTPUT_DIR/kneaddataOutput/*/*_kneaddata.fastq -o $FASTQC_OUTPUT_DIR

# Run MultiQC to aggregate FastQC results
multiqc $FASTQC_OUTPUT_DIR -o $MULTIQC_OUTPUT_DIR

# Print message indicating completion
echo "FastQC and MultiQC analysis complete. Check the MultiQC report at $MULTIQC_OUTPUT_DIR/multiqc_report.html"