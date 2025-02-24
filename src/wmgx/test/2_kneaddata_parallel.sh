#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J kd_SUBSTITUTION_BIO_ID
#SBATCH -t 150:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/SUBSTITUTION_BIO_ID_kneaddata_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/SUBSTITUTION_BIO_ID_kneaddata_%j.err
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

BIOPROJECT="test"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Extract SRR IDs and Library Layouts from the CSV file
SRR_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $1, $16}' "$META_CSV_FILE")  # Adjust the column number for "Library Layout"

# Functions to process SRR IDs
process_single_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="test"
    local CPUS=20
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
    echo "Processing single-end SRR ID: $SRR_ID"
    mkdir -p $OUTPUT_DIR/${SRR_ID}
    kneaddata --unpaired $INPUT_FASTQ_DIR/${SRR_ID}_1_clean_final.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_genomic/GRCh38_index \
              --reference-db $REFERENCE_DB/ribosomal_RNA \
              --output $OUTPUT_DIR/${SRR_ID}
    pigz -p $CPUS $OUTPUT_DIR/${SRR_ID}/*.fastq
}

process_paired_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="test"
    local CPUS=20
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
    echo "Processing paired-end SRR ID: $SRR_ID"
    mkdir -p $OUTPUT_DIR/${SRR_ID}
    kneaddata --input1 $INPUT_FASTQ_DIR/${SRR_ID}_1_clean_final.fastq.gz \
              --input2 $INPUT_FASTQ_DIR/${SRR_ID}_2_clean_final.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_genomic/GRCh38_index \
              --reference-db $REFERENCE_DB/ribosomal_RNA \
              --output $OUTPUT_DIR/${SRR_ID}
    pigz -p $CPUS $OUTPUT_DIR/${SRR_ID}/*.fastq
}

process_srr_id() {
    local SRR_ID=$1
    local LAYOUT=$2
    local BIOPROJECT="test"
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
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
MERGED_KNEADDATA_CSV="$OUTPUT_DIR/${BIOPROJECT}_merged_kneaddata_reads_table.csv"

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
    local BIOPROJECT="test"
    local CPUS=20
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
    local FASTQC_OUTPUT="$OUTPUT_DIR/fastqc_kneaddata"
    mkdir -p $FASTQC_OUTPUT
    echo "fastqc paired-end SRR ID: $SRR_ID"
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata.fastq.gz -o $OUTPUT_DIR 
}

fastqc_paired_end_srr_id() {
    local SRR_ID=$1
    local BIOPROJECT="test"
    local CPUS=20
    local INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"
    local OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
    local FASTQC_OUTPUT="$OUTPUT_DIR/fastqc_kneaddata"
    mkdir -p $FASTQC_OUTPUT
    echo "fastqc paired-end SRR ID: $SRR_ID"
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata_paired_1.fastq.gz $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata_paired_2.fastq.gz -o $FASTQC_OUTPUT 
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
MUTIQC_OUTPUT="$OUTPUT_DIR/multiqc_output_kneaddata"
mkdir -p $MUTIQC_OUTPUT
multiqc $OUTPUT_DIR -o $MUTIQC_OUTPUT



# Define the directory for merged files
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
MERGED_TSV="${MERGED_DIR}/${BIOPROJECT}_kneaddata_remove_low_reads_merge_samples.csv"


# Run the Python script to filter and merge samples
python /proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/kneaddata_remove_low_reads_merge_samples.py "${OUTPUT_DIR}/${BIOPROJECT}_merged_kneaddata_reads_table.csv" "${META_CSV_FILE}" "${MERGED_TSV}"
# Create the merged directory if it doesn't exist
mkdir -p "${MERGED_DIR}"

# Read the CSV file line by line
while IFS=',' read -r sample_id NCBI_accession; do

    # Skip header or empty lines
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    # Split the NCBI_accessions by commas
    IFS=',' read -r -a accession_array <<< "$NCBI_accession"

    # Prepare output filenames
    forward_output="${MERGED_DIR}/${sample_id}_kneaddata_paired_1.fastq.gz"
    reverse_output="${MERGED_DIR}/${sample_id}_kneaddata_paired_2.fastq.gz"
    single_output="${MERGED_DIR}/${sample_id}_kneaddata_single.fastq.gz"

    # Initialize temporary files
    temp_forward=$(mktemp)
    temp_reverse=$(mktemp)
    temp_single=$(mktemp)

    # Determine if the sample is paired or single
    is_paired=false
    echo "$SRR_IDS_AND_LAYOUTS" | while read -r SRR_ID LAYOUT; do
        echo $LAYOUT
        if [ "$LAYOUT" == "PAIRED" ]; then
            is_paired=true
            break
        fi
    done

    # Iterate over each accession and build the file paths
    for accession in "${accession_array[@]}"; do
        if $is_paired; then
            if [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_1.fastq.gz" ]]; then
                cat "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_1.fastq.gz" >> "$temp_forward"
            fi

            if [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_2.fastq.gz" ]]; then
                cat "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata_paired_2.fastq.gz" >> "$temp_reverse"
            fi
        else
            if [[ -f "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata.fastq.gz" ]]; then
                cat "${OUTPUT_DIR}/${accession}/${accession}_1_clean_final_kneaddata.fastq.gz" >> "$temp_single"
            fi
        fi
    done

    # Compress the merged paired files with pigz
    if $is_paired; then
        pigz -p $CPUS < "$temp_forward" > "$forward_output"
        pigz -p $CPUS < "$temp_reverse" > "$reverse_output"
        rm "$temp_forward" "$temp_reverse"
    else
        pigz -p $CPUS < "$temp_single" > "$single_output"
        rm "$temp_single"
    fi

done < "$MERGED_TSV"

# If all files are valid, submit the third script
echo "All files processed successfully."