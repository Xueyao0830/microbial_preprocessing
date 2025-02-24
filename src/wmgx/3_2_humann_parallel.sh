#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J hm_SUBSTITUTION_BIO_ID
#SBATCH -t 100:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/3_2_humann.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/3_2_humann.err
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
CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_1_metaphlan"
ANALYSIS_HM_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_2_humann"
CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

mkdir -p $ANALYSIS_HM_DIR

# Read the batch-specific SAMPLE_ID and LAYOUT from the dynamically passed file
SAMPLE_IDS_AND_LAYOUTS=$(cat samples_and_layouts_batch)


humann_single_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
    local ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_1_metaphlan"
    local ANALYSIS_HM_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_2_humann"
    local METAPHLAN_BUGS_LIST="$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"
    local INPUT_FILE="$MERGED_DIR/${SAMPLE_ID}_kneaddata_single.fastq.gz"

    mkdir -p "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
    echo "Single-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file: $INPUT_FILE"
    if [ -f "$INPUT_FILE" ]; then
       humann   -i "$INPUT_FILE" \
                -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}  \
                --verbose \
                --metaphlan-options "-t rel_ab --index latest" \
                --taxonomic-profile $METAPHLAN_BUGS_LIST \
                --threads 20
       humann_renorm_table \
                --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance.tsv \
                --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance_cpm.tsv \
                --units cpm

       humann_renorm_table \
                --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilies.tsv \
                --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilies_cpm.tsv \
                --units cpm

       humann_renorm_table \
                --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilies.tsv \
                --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilies_relab.tsv \
                --units relab

       humann_renorm_table \
                --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance.tsv \
                --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance_relab.tsv \
                --units relab

       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance_cpm.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathabundance_relab.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_pathcoverage.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilie.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilies_cpm.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_single_genefamilies_relab.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
    else
        echo "File not found: $INPUT_FILE"
    fi 
}

humann_paired_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
    local ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_1_metaphlan"
    local ANALYSIS_HM_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_2_humann"
    local METAPHLAN_BUGS_LIST="$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"

    local INPUT_FILE_1="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_1.fastq.gz"
    local INPUT_FILE_2="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_2.fastq.gz"
    local PAIRED_MERGED="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_merged.fastq.gz"

    mkdir -p "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
    echo "Paired-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file 1: $INPUT_FILE_1"
    echo "Input file 2: $INPUT_FILE_2"
    if [ -f "$INPUT_FILE_1" ] && [ -f "$INPUT_FILE_2" ]; then
       cat "$INPUT_FILE_1" "$INPUT_FILE_2" >> "$PAIRED_MERGED"
       humann   -i "$PAIRED_MERGED" \
                      -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}  \
                      --verbose \
                      --metaphlan-options "-t rel_ab --index latest" \
                      --taxonomic-profile $METAPHLAN_BUGS_LIST \
                      --threads 20
       humann_renorm_table \
                      --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance.tsv \
                      --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance_cpm.tsv \
                      --units cpm

       humann_renorm_table \
                      --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies.tsv \
                      --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies_cpm.tsv \
                      --units cpm

       humann_renorm_table \
                      --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies.tsv \
                      --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies_relab.tsv \
                      --units relab

       humann_renorm_table \
                      --input "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance.tsv \
                      --output "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance_relab.tsv \
                      --units relab

       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance_cpm.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathabundance_relab.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_pathcoverage.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies_cpm.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
       humann_split_stratified_table -i "$ANALYSIS_HM_DIR"/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata_paired_merged_genefamilies_relab.tsv -o "$ANALYSIS_HM_DIR"/${SAMPLE_ID}
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

# Run the function for each sample ID in parallel
echo "$SAMPLE_IDS_AND_LAYOUTS" | while read SAMPLE_ID LAYOUT; do
    parallel -j $CPUS humann_sample_id ::: $SAMPLE_ID ::: $LAYOUT
done

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))

# Convert runtime from seconds to hours
runtime_hours=$(echo "scale=2; $runtime / 3600" | bc)

echo "Job running time: $runtime_hours hours"




