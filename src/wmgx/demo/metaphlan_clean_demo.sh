#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J metaphlan_BIOPROJECT_PLACEHOLDER
#SBATCH -t 30:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/log/process/test_process_clean_metaphlan_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/log/process/test_process_clean_metaphlan_%j.err

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist

# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC

BIOPROJECT="test_process_clean"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics_clean/$BIOPROJECT"
SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"

CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Extract SRR IDs from the input directory
SRR_IDS=$(ls $INPUT_FASTQ_DIR/*_{1,2}.fastq.gz | xargs -n 1 basename | cut -d '_' -f 1 | sort | uniq)


metaphlan_single_end_srr_id() {
    local SRR_ID=$1
    metaphlan $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_kneaddata.fastq \
              --bowtie2out $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_metagenome.bowtie2.bz2 \
              --input_type fastq --nproc 16 \
              --sample_id $SRR_ID \
              -t rel_ab_w_read_stats \
              -o $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_kneaddata_profile.txt
}

metaphlan_paired_end_srr_id() {
    local SRR_ID=$1
    metaphlan $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_kneaddata_paired_1.fastq,$OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_kneaddata_paired_2.fastq \
              --bowtie2out $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_metagenome.bowtie2.bz2 \
              --input_type fastq --nproc 16 \
              --sample_id $SRR_ID \
              -t rel_ab_w_read_stats \
              -o $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_kneaddata_profile.txt
}

metaphlan_srr_id() {
    local SRR_ID=$1
    if [ -f ${INPUT_FASTQ_DIR}/${SRR_ID}_2.fastq.gz ]; then
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

echo $SRR_IDS 

# Run process_srr_id in parallel for each SRR_ID
for SRR_ID in $SRR_IDS; do
    metaphlan_srr_id $SRR_ID
done

# Merge MetaPhlAn tables
METAPHLAN_OUTPUTS=$(for SRR_ID in $SRR_IDS; do echo $OUTPUT_DIR/$SRR_ID/${SRR_ID}_kneaddata_profile.txt; done)
python $SRC_UTILS/merge_metaphlan_table_absolute.py $METAPHLAN_OUTPUTS > $OUTPUT_DIR/${BIOPROJECT}_merged_absolute_abundance_table.txt