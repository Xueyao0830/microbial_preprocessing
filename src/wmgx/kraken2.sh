#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J 389927_metaphlan
#SBATCH -t 30:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/metaphlan_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/metaphlan_%j.err
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
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Bracken-2.9

Name='Archaea Bacteria fungi viral'




BIOPROJECT="PRJNA389927"

REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/${BIOPROJECT}"
SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"

CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Extract SRR IDs and Library Layouts from the CSV file
SRR_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $1, $16}' "$CSV_FILE")  # Adjust the column number for "Library Layout"

metaphlan_single_end_srr_id() {
    local SRR_ID=$1
    local INPUT_FILE="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata.fastq"
    echo "Single-end processing SRR_ID: $SRR_ID"
    echo "Input file: $INPUT_FILE"
    if [ -f "$INPUT_FILE" ]; then
        metaphlan "$INPUT_FILE" \
                  --bowtie2out "$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_clean_final_metagenome.bowtie2.bz2" \
                  --input_type fastq --nproc $CPUS \
                  --sample_id $SRR_ID \
                  -t rel_ab_w_read_stats \
                  -o "$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_clean_final_kneaddata_profile.txt"
    else
        echo "File not found: $INPUT_FILE"
    fi
}

metaphlan_paired_end_srr_id() {
    local SRR_ID=$1
    local INPUT_FILE_1="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata_paired_1.fastq"
    local INPUT_FILE_2="$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata_paired_2.fastq"
    echo "Paired-end processing SRR_ID: $SRR_ID"
    echo "Input file 1: $INPUT_FILE_1"
    echo "Input file 2: $INPUT_FILE_2"
    if [ -f "$INPUT_FILE_1" ] && [ -f "$INPUT_FILE_2" ]; then
        metaphlan "$INPUT_FILE_1","$INPUT_FILE_2" \
                  --bowtie2out "$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_clean_final_metagenome.bowtie2.bz2" \
                  --input_type fastq --nproc $CPUS \
                  --sample_id $SRR_ID \
                  -t rel_ab_w_read_stats \
                  -o "$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_clean_final_kneaddata_profile.txt"
    else
        echo "Paired files not found: $INPUT_FILE_1 or $INPUT_FILE_2"
    fi
}

metaphlan_srr_id() {
    local SRR_ID=$1
    local LAYOUT=$2
    if [ "$LAYOUT" == "PAIRED" ]; then
        echo "metaphlan paired-end SRR ID: $SRR_ID"
        metaphlan_paired_end_srr_id $SRR_ID
    else
        echo "metaphlan single-end SRR ID: $SRR_ID"
        metaphlan_single_end_srr_id $SRR_ID
    fi
}

export -f metaphlan_single_end_srr_id
export -f metaphlan_paired_end_srr_id
export -f metaphlan_srr_id

echo "$SRR_IDS_AND_LAYOUTS"

# Run process_srr_id sequentially for each SRR_ID
echo "$SRR_IDS_AND_LAYOUTS" | while read SRR_ID LAYOUT; do
    metaphlan_srr_id $SRR_ID $LAYOUT
done

# Merge MetaPhlAn tables
METAPHLAN_OUTPUTS=$(for SRR_ID in $(echo "$SRR_IDS_AND_LAYOUTS" | awk '{print $1}'); do echo "$OUTPUT_DIR/$SRR_ID/${SRR_ID}_clean_final_kneaddata_profile.txt"; done)
python $SRC_UTILS/merge_metaphlan_table_absolute.py $METAPHLAN_OUTPUTS > "$OUTPUT_DIR/${BIOPROJECT}_clean_final_merged_absolute_abundance_table.txt"

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"