#!/bin/bash

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist
module load parallel/20181122-nsc1


# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC

source ~/.bashrc

BIOPROJECT="PRJEB10878"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
CPUS=20


# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"


kneaddata --input1 $INPUT_FASTQ_DIR/${SRR_ID}_1_clean_final.fastq \
          --input2 $INPUT_FASTQ_DIR/${SRR_ID}_2_clean_final.fastq \
          --reference-db $REFERENCE_DB/GRCh38_index \
          --output $OUTPUT_DIR/${SRR_ID}

              
SRR_IDS=$(ls $INPUT_FASTQ_DIR/*_{1,2}_clean_final.fastq | xargs -n 1 basename | cut -d '_' -f 1 | sort | uniq)

check_log() {
     local SRR_ID=$1
     if ! grep -q 'Final output files created:' $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata.log; then
        echo "Log file for ${SRR_ID} does not contain 'Final output files created:'. Running kneaddata."
     fi
}


for SRR_ID in $SRR_IDS; do
    check_log $SRR_ID
done

