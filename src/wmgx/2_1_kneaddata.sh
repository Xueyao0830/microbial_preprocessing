#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J kd_SUBSTITUTION_BIO_ID
#SBATCH -t 120:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/2_1_kneaddata.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/2_1_kneaddata.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xueyao.wang@ki.se

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist
module load parallel/20181122-nsc1

# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC

BIOPROJECT="SUBSTITUTION_BIO_ID"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"
META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
LOG_FILE="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata.log"
RESULT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/result"
CPUS=20


FASTQC_OUTPUT="$OUTPUT_DIR/fastqc_kneaddata"
MUTIQC_OUTPUT="$RESULT_DIR/${BIOPROJECT}_multiqc_output_kneaddata"


# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"


mkdir -p $OUTPUT_DIR
mkdir -p $RESULT_DIR
mkdir -p $FASTQC_OUTPUT
mkdir -p $MUTIQC_OUTPUT

# Extract SRR IDs and Library Layouts from the CSV file
SRR_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $1, $16}' "$META_CSV_FILE")  # Adjust the column number for "Library Layout"

# Functions to process SRR IDs
process_single_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"
    local META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
    local LOG_FILE="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata.log"
    local CPUS=20

    # Check if kneaddata has already completed
    if grep -q "Final output files created" "$LOG_FILE"; then
        echo "Kneaddata already completed for single-end SRR ID: $SRR_ID, skipping."
    else
        echo "Processing single-end SRR ID: $SRR_ID"
        mkdir -p $OUTPUT_DIR/${SRR_ID}
        kneaddata --unpaired $INPUT_FASTQ_DIR/${SRR_ID}_0_WGS_clean_final.fastq.gz \
                  --reference-db $REFERENCE_DB/GRCh38_genomic/GRCh38_index \
                  --reference-db $REFERENCE_DB/ribosomal_RNA \
                  --output $OUTPUT_DIR/${SRR_ID}
        pigz -p $CPUS $OUTPUT_DIR/${SRR_ID}/*.fastq
    fi
}

process_paired_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"
    local META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
    local LOG_FILE="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata.log"
    local CPUS=20
    
    # Check if kneaddata has already completed
    if grep -q "Final output files created" "$LOG_FILE"; then
        echo "Kneaddata already completed for paired-end SRR ID: $SRR_ID, skipping."
    else
        echo "Processing paired-end SRR ID: $SRR_ID"
        mkdir -p $OUTPUT_DIR/${SRR_ID}
        kneaddata --input1 $INPUT_FASTQ_DIR/${SRR_ID}_1_WGS_clean_final.fastq.gz \
                  --input2 $INPUT_FASTQ_DIR/${SRR_ID}_2_WGS_clean_final.fastq.gz \
                  --reference-db $REFERENCE_DB/GRCh38_genomic/GRCh38_index \
                  --reference-db $REFERENCE_DB/ribosomal_RNA \
                  --output $OUTPUT_DIR/${SRR_ID}
        pigz -p $CPUS $OUTPUT_DIR/${SRR_ID}/*.fastq
    fi
}

process_srr_id() {
    local SRR_ID=$1
    local LAYOUT=$2
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/1_2_sed"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"
    local META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
    local LOG_FILE="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata.log"

    if [ "$LAYOUT" == "PAIRED" ]; then
        process_paired_end_srr_id $SRR_ID
    else
        process_single_end_srr_id $SRR_ID
    fi
}

# Export functions to be used by parallel
export -f process_single_end_srr_id
export -f process_paired_end_srr_id
export -f process_srr_id

# Check each SRR ID for completion and re-process if needed
echo "$SRR_IDS_AND_LAYOUTS" | parallel -j $CPUS --colsep ' ' 'process_srr_id {1} {2}'

# Generate kneaddata read count table for all processed SRR IDs
MERGED_KNEADDATA_CSV="$RESULT_DIR/${BIOPROJECT}_merged_kneaddata_reads_table.csv"

# Loop through SRR IDs and Layouts
echo "$SRR_IDS_AND_LAYOUTS" | while read -r SRR_ID LAYOUT; do
    # Generate kneaddata read count table for the SRR ID
    kneaddata_read_count_table --input $OUTPUT_DIR/${SRR_ID} --output $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_clean_kneaddata_read_count_table.tsv
done

# Initialize the output file and write the header
first_file=$(find $OUTPUT_DIR -name "*_clean_kneaddata_read_count_table.tsv" | head -n 1)
if [[ -n "$first_file" ]]; then
    head -n 1 "$first_file" > "$MERGED_KNEADDATA_CSV"
else
    echo "No kneaddata read count table files found."
    exit 1
fi

# Loop through the files and append them to the output file
find $OUTPUT_DIR -name "*_clean_kneaddata_read_count_table.tsv" | while read file; do
    tail -n +2 "$file" >> "$MERGED_KNEADDATA_CSV"
done

echo "Merged $(find $OUTPUT_DIR -name "*_clean_kneaddata_read_count_table.tsv" | wc -l) files into $MERGED_KNEADDATA_CSV"



fastqc_single_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"

    local FASTQC_OUTPUT="$OUTPUT_DIR/fastqc_kneaddata"


    echo "fastqc paired-end SRR ID: $SRR_ID"
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata.fastq.gz -o $OUTPUT_DIR 
}

fastqc_paired_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_1_kneaddata"

    local FASTQC_OUTPUT="$OUTPUT_DIR/fastqc_kneaddata"

    echo "fastqc paired-end SRR ID: $SRR_ID"
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata_paired_1.fastq.gz $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_WGS_clean_final_kneaddata_paired_2.fastq.gz -o $FASTQC_OUTPUT 
}

export -f fastqc_single_end_srr_id
export -f fastqc_paired_end_srr_id

# Run FastQC in parallel
echo "$SRR_IDS_AND_LAYOUTS" | parallel -j $CPUS --colsep ' ' '
    SRR_ID={1};
    LAYOUT={2};
    if [ "$LAYOUT" == "PAIRED" ]; then
        fastqc_paired_end_srr_id {1} {2}
    else
        fastqc_single_end_srr_id {1} {2}
    fi
'

# Run MultiQC to aggregate FastQC results
multiqc $FASTQC_OUTPUT -o $MUTIQC_OUTPUT


# If all files are valid, submit the third script
echo "All files processed successfully."
# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))

# Convert runtime from seconds to hours
runtime_hours=$(echo "scale=2; $runtime / 3600" | bc)

echo "Job running time: $runtime_hours hours"