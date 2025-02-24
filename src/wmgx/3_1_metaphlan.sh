#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J mp_SUBSTITUTION_BIO_ID
#SBATCH -t 80:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/3_1_metaphlan.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomics/preprocessing/SUBSTITUTION_BIO_ID/3_1_metaphlan.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xueyao.wang@ki.se

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist

# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC
source ~/.bashrc

BIOPROJECT="SUBSTITUTION_BIO_ID"
SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"
CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
SAMPLE_KD_CSV="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/result/${BIOPROJECT}_kneaddata_remove_low_reads_merge_samples.tsv"
MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_1_metaphlan"
RESULT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/result"

CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"


mkdir -p $ANALYSIS_MP_DIR
mkdir -p $OUTPUT_DIR

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    echo "CSV file not found: $CSV_FILE"
    exit 1
fi

# Extract SAMPLE IDs and Library Layouts from the CSV file
#SAMPLE_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $26, $16}' "$CSV_FILE")  # Adjust the column number for "Library Layout"
# Extract SAMPLE IDs and Library Layouts from the CSV file
#LAYOUTS=$(awk -F, 'NR>1 {print $16}' "$CSV_FILE")  # Adjust the column number for "Library Layout"
SAMPLE_IDS=$(awk 'NR > 1 {print $1}' "$SAMPLE_KD_CSV")


metaphlan_single_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
    local ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_1_metaphlan"
    local INPUT_FILE="$MERGED_DIR/${SAMPLE_ID}_kneaddata_single.fastq.gz"
    local ANALYSIS_SAMPLE_DIR="$ANALYSIS_MP_DIR/${SAMPLE_ID}"

    mkdir -p "$ANALYSIS_SAMPLE_DIR"
    echo "Single-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file: $INPUT_FILE"
    if [ -f "$INPUT_FILE" ]; then
        metaphlan "$INPUT_FILE" \
            --bowtie2out "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type fastq --nproc $CPUS \
            --samout "$ANALYSIS_SAMPLE_DIR/sam.bz2" \
            --sample_id "$SAMPLE_ID" \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"
        
        metaphlan "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type bowtie2out --nproc $CPUS --sample_id "$SAMPLE_ID" \
            -t rel_ab_w_read_stats \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_rel_ab_w_read_stats_kneaddata.csv"
        
        metaphlan "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type bowtie2out --nproc $CPUS --sample_id "$SAMPLE_ID" \
            -t marker_ab_table \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_marker_abundance_kneaddata.csv"
        
        metaphlan "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type bowtie2out --nproc $CPUS --sample_id "$SAMPLE_ID" \
            -t marker_pres_table \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_marker_presence_kneaddata.csv"
    else
        echo "Single-end input file not found: $INPUT_FILE"
    fi
}

metaphlan_paired_end_sample_id() {
    local SAMPLE_ID=$1
    local BIOPROJECT="SUBSTITUTION_BIO_ID"
    local MERGED_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/2_2_merged_kd"
    local ANALYSIS_MP_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT/3_1_metaphlan"
    local INPUT_FILE_1="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_1.fastq.gz"
    local INPUT_FILE_2="$MERGED_DIR/${SAMPLE_ID}_kneaddata_paired_2.fastq.gz"
    local ANALYSIS_SAMPLE_DIR="$ANALYSIS_MP_DIR/${SAMPLE_ID}"

    mkdir -p "$ANALYSIS_SAMPLE_DIR"
    echo "Paired-end processing SAMPLE_ID: $SAMPLE_ID"
    echo "Input file 1: $INPUT_FILE_1"
    echo "Input file 2: $INPUT_FILE_2"
    if [ -f "$INPUT_FILE_1" ] && [ -f "$INPUT_FILE_2" ]; then
        metaphlan "$INPUT_FILE_1","$INPUT_FILE_2" \
            --bowtie2out "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type fastq --nproc $CPUS \
            --samout "$ANALYSIS_SAMPLE_DIR/sam.bz2" \
            --sample_id "$SAMPLE_ID" \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_metaphlan_bugs_list_kneaddata.tsv"
        
        metaphlan "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type bowtie2out --nproc $CPUS --sample_id "$SAMPLE_ID" \
            -t rel_ab_w_read_stats \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_rel_ab_w_read_stats_kneaddata.csv"
        
        metaphlan "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type bowtie2out --nproc $CPUS --sample_id "$SAMPLE_ID" \
            -t marker_ab_table \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_marker_abundance_kneaddata.csv"
        
        metaphlan "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_kneaddata.bowtie2.bz2" \
            --input_type bowtie2out --nproc $CPUS --sample_id "$SAMPLE_ID" \
            -t marker_pres_table \
            -o "$ANALYSIS_SAMPLE_DIR/${SAMPLE_ID}_marker_presence_kneaddata.csv"
    else
        echo "Paired-end input files not found: $INPUT_FILE_1 or $INPUT_FILE_2"
    fi
}

while IFS= read -r SAMPLE_ID; do
    # Find the corresponding row in CSV_FILE that matches the SAMPLE_ID and get the LAYOUT (column 16)
    LAYOUT=$(awk -F, -v id="$SAMPLE_ID" '$26 == id {print $16}' "$CSV_FILE")
    
    if [ "$LAYOUT" == "PAIRED" ]; then
        metaphlan_paired_end_sample_id "$SAMPLE_ID"
    else
        metaphlan_single_end_sample_id "$SAMPLE_ID"
    fi
done <<< "$SAMPLE_IDS"


# Merge MetaPhlAn tables
# Initialize an empty string to store the file paths
METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS=""
for SAMPLE_ID in $SAMPLE_IDS; do 
    METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS+="$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_rel_ab_w_read_stats_kneaddata.csv "
done
python $SRC_UTILS/merge_metaphlan_table_absolute.py $METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS > "$RESULT_DIR/${BIOPROJECT}_merged_absolute_abundance_kneaddata_metaphlan4.csv"
python $SRC_UTILS/merge_metaphlan_tables.py $METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS > "$RESULT_DIR/${BIOPROJECT}_merged_relative_abundance_kneaddata_metaphlan4.csv"


METAPHLAN_MARKER_ABUNDANCE_OUTPUTS=""
for SAMPLE_ID in $SAMPLE_IDS; do 
    METAPHLAN_MARKER_ABUNDANCE_OUTPUTS+="$ANALYSIS_MP_DIR/${SAMPLE_ID}/${SAMPLE_ID}_marker_abundance_kneaddata.csv "
done


python $SRC_UTILS/merge_metaphlan_table_marker_abundance.py $METAPHLAN_MARKER_ABUNDANCE_OUTPUTS -o "$RESULT_DIR/${BIOPROJECT}_merged_marker_abundance_kneaddata_metaphlan4.csv"

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))

# Convert runtime from seconds to hours
runtime_hours=$(echo "scale=2; $runtime / 3600" | bc)

echo "Job running time: $runtime_hours hours"