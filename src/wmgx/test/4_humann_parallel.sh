#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J mp_test_metaphlan
#SBATCH -t 30:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o/proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/test_metaphlan_ID_metaphlan_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/test_metaphlan_ID_metaphlan_%j.err
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
source ~/.bashrc

BIOPROJECT="test_metaphlan"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
ANALYSIS_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/analysis/metagenomics/$BIOPROJECT"

CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Extract SAMPLE IDs and Library Layouts from the CSV file
SAMPLE_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $30, $16}' "$CSV_FILE")  # Adjust the column number for "Library Layout"



humann_single_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="test_metaphlan"
    local SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
    local CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
    local INPUT_FILE="$MERGED_DIR/${SAMPLE_ID}_kneaddata_single.fastq.gz"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
    local ANALYSIS_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/analysis/metagenomics/$BIOPROJECT"
    local METAPHLAN_BUGS_LIST="$ANALYSIS_DIR/${SAMPLE_ID}/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"
    echo "Single-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file: $INPUT_FILE"
    if [ -f "$INPUT_FILE" ]; then
       time  humann   -i "$INPUT_FILE" \
                      -o "$ANALYSIS_DIR"  \
                      --verbose \
                      --metaphlan-options "-t rel_ab --index latest" \
                      --taxonomic-profile ${METAPHLAN_BUGS_LIST} \
                      --threads 20
       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_cpm.tsv \
                      --units cpm

       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_cpm.tsv \
                      --units cpm

       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_relab.tsv \
                      --units relab

       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_relab.tsv \
                      --units relab

       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_cpm.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_relab.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathcoverage.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_cpm.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_relab.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
    else
        echo "File not found: $INPUT_FILE"
    fi 
}

humann_paired_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="test_metaphlan"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
    local SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
    local CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
    local INPUT_FILE_1="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_1.fastq.gz"
    local INPUT_FILE_2="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_2.fastq.gz"
    local PAIRED_MERGED="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_merged.fastq.gz"
    local ANALYSIS_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/analysis/metagenomics/$BIOPROJECT"
    local METAPHLAN_BUGS_LIST="$ANALYSIS_DIR/${SAMPLE_ID}/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"

    echo "Paired-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file 1: $INPUT_FILE_1"
    echo "Input file 2: $INPUT_FILE_2"
    if [ -f "$INPUT_FILE_1" ] && [ -f "$INPUT_FILE_2" ]; then
       cat "$INPUT_FILE_1" "$INPUT_FILE_2" >> "$PAIRED_MERGED"
       time  humann   -i "$PAIRED_MERGED" \
                      -o "$ANALYSIS_DIR"/${SAMPLE_ID}  \
                      --verbose \
                      --metaphlan-options "-t rel_ab --index latest" \
                      --taxonomic-profile ${METAPHLAN_BUGS_LIST} \
                      --threads 20
       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_cpm.tsv \
                      --units cpm

       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_cpm.tsv \
                      --units cpm

       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_relab.tsv \
                      --units relab

       time  humann_renorm_table \
                      --input "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance.tsv \
                      --output "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_relab.tsv \
                      --units relab

       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_cpm.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathabundance_relab.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_pathcoverage.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_cpm.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       time  humann_split_stratified_table -i "$ANALYSIS_DIR"/${SAMPLE_ID}/out_genefamilies_relab.tsv -o "$ANALYSIS_DIR"/${SAMPLE_ID}
       rm $PAIRED_MERGED
    else
        echo "File not found: $INPUT_FILE"
    fi 
}

humann_sample_id() {
    local SAMPLE_ID=$1
    local LAYOUT=$2
    if [ "$LAYOUT" == "PAIRED" ]; then
        echo "humann paired-end SAMPLE ID: $SAMPLE_ID"
        humann_paired_end_sample_id $SAMPLE_ID
    else
        echo "humann single-end SAMPLE ID: $SAMPLE_ID"
        humann_single_end_sample_id $SAMPLE_ID
    fi
}

export -f humann_single_end_sample_id
export -f humann_paired_end_sample_id
export -f humann_sample_id

echo "$SAMPLE_IDS_AND_LAYOUTS"

# Run process_srr_id in parallel for each SRR_ID
echo "$SAMPLE_IDS_AND_LAYOUTS" | while read SAMPLE_ID LAYOUT; do
    parallel -j $CPUS humann_sample_id ::: $SAMPLE_ID ::: $LAYOUT
done








