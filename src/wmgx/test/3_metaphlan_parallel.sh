#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J mp_test
#SBATCH -t 30:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o/proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/test_metaphlan_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/test_metaphlan_%j.err
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

BIOPROJECT="test"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/analysis/metagenomics/$BIOPROJECT/metaphlan"

CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"
mkdir -p $ANALYSIS_MP_DIR
# Extract SAMPLE IDs and Library Layouts from the CSV file
SAMPLE_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $30, $16}' "$CSV_FILE")  # Adjust the column number for "Library Layout"

metaphlan_single_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="test"
    local SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
    local CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
    local INPUT_FILE="$MERGED_DIR/${SAMPLE_ID}_kneaddata_single.fastq.gz"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
    local ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/analysis/metagenomics/$BIOPROJECT/metaphlan"
    mkdir -p "$ANALYSIS_MP_DIR/${SAMPLE_ID}"
    echo "Single-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file: $INPUT_FILE"
    if [ -f "$INPUT_FILE" ]; then
        metaphlan "$INPUT_FILE" \
                      --bowtie2out "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type fastq --nproc 20 \
                      --samout sam.bz2 \
                      --sample_id $SAMPLE_ID \
                      --nproc 20 \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"
        metaphlan "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type bowtie2out \
                      --nproc 20 \
                      --sample_id $SAMPLE_ID \
                      -t rel_ab_w_read_stats \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_rel_ab_w_read_stats_kneaddata.csv"
        metaphlan "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type bowtie2out \
                      --nproc 20 \
                      --sample_id $SAMPLE_ID \
                      -t marker_ab_table \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_marker_abundance_kneaddata.csv"
        metaphlan "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type bowtie2out \
                      --nproc 20 \
                      --sample_id $SAMPLE_ID \
                      -t marker_pres_table \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_marker_presence_kneaddata.csv"
    else
        echo "Paired files not found: $INPUT_FILE_1 or $INPUT_FILE_2"
    fi
}

metaphlan_paired_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="test"
    local REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
    local SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
    local CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/merged_metageomics/$BIOPROJECT"
    local INPUT_FILE_1="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_1.fastq.gz"
    local INPUT_FILE_2="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_2.fastq.gz"
    local ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/project/mm_network/analysis/metagenomics/$BIOPROJECT/metaphlan"
    mkdir -p "$ANALYSIS_MP_DIR/${SAMPLE_ID}"
    echo "Paired-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file 1: $INPUT_FILE_1"
    echo "Input file 2: $INPUT_FILE_2"
    if [ -f "$INPUT_FILE_1" ] && [ -f "$INPUT_FILE_2" ]; then
        metaphlan "$INPUT_FILE_1","$INPUT_FILE_2" \
                      --bowtie2out "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type fastq --nproc 20 \
                      --samout sam.bz2 \
                      --sample_id $SAMPLE_ID \
                      --nproc 20 \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"
        metaphlan "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type bowtie2out \
                      --nproc 20 \
                      --sample_id $SAMPLE_ID \
                      -t rel_ab_w_read_stats \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_rel_ab_w_read_stats_kneaddata.csv"
        metaphlan "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type bowtie2out \
                      --nproc 20 \
                      --sample_id $SAMPLE_ID \
                      -t marker_ab_table \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_marker_abundance_kneaddata.csv"
        metaphlan "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
                      --input_type bowtie2out \
                      --nproc 20 \
                      --sample_id $SAMPLE_ID \
                      -t marker_pres_table \
                      -o "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_marker_presence_kneaddata.csv"
    else
        echo "Paired files not found: $INPUT_FILE_1 or $INPUT_FILE_2"
    fi
}

metaphlan_sample_id() {
    local SAMPLE_ID=$1
    local LAYOUT=$2
    if [ "$LAYOUT" == "PAIRED" ]; then
        echo "metaphlan paired-end SAMPLE ID: $SAMPLE_ID"
        metaphlan_paired_end_sample_id $SAMPLE_ID
    else
        echo "metaphlan single-end SAMPLE ID: $SAMPLE_ID"
        metaphlan_single_end_sample_id $SAMPLE_ID
    fi
}

export -f metaphlan_single_end_sample_id
export -f metaphlan_paired_end_sample_id
export -f metaphlan_sample_id

echo "$SAMPLE_IDS_AND_LAYOUTS"

# Run process_srr_id in parallel for each SRR_ID
echo "$SAMPLE_IDS_AND_LAYOUTS" | while read SAMPLE_ID LAYOUT; do
    parallel -j $CPUS metaphlan_sample_id ::: $SAMPLE_ID ::: $LAYOUT
done

# Merge MetaPhlAn tables
METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS=$(for SAMPLE_ID in $(echo "$SAMPLE_IDS_AND_LAYOUTS" | awk '{print $1}'); do echo "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_rel_ab_w_read_stats_kneaddata.csv"; done)
python $SRC_UTILS/merge_metaphlan_table_absolute.py $METAPHLAN_OUTPUTS > "$ANALYSIS_MP_DIR/${BIOPROJECT}_merged_absolute_abundance_kneaddata.csv"

METAPHLAN_MARKER_ABUNDANCE_OUTPUTS=$(for SAMPLE_ID in $(echo "$SAMPLE_IDS_AND_LAYOUTS" | awk '{print $1}'); do echo "$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_marker_abundance_kneaddata.csv"; done)

python $SRC_UTILS/merge_metaphlan_table_marker_abundance.py $METAPHLAN_MARKER_ABUNDANCE_OUTPUTS -o "$ANALYSIS_MP_DIR/${BIOPROJECT}_merged_marker_abundance_kneaddata.csv"



# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))

# Convert runtime from seconds to hours
runtime_hours=$(echo "scale=2; $runtime / 3600" | bc)

echo "Job running time: $runtime_hours hours"