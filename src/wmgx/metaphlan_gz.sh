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

BIOPROJECT="test_gz"

REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/${BIOPROJECT}"
SRC_UTILS="/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils"

CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Extract SRR IDs and Library Layouts from the CSV file
SRR_ID="SRR5665009" # Adjust the column number for "Library Layout"


metaphlan_paired_end_srr_id() {
    local SRR_ID=$1
    local INPUT_FILE_1="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/test_gz/SRR5665009/SRR5665009_1_clean_final_kneaddata_paired_1.fastq.gz"
    local INPUT_FILE_2="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/test_gz/SRR5665009/SRR5665009_1_clean_final_kneaddata_paired_1.fastq.gz"
    echo "Paired-end processing SRR_ID: $SRR_ID"
    echo "Input file 1: $INPUT_FILE_1"
    echo "Input file 2: $INPUT_FILE_2"
    if [ -f "$INPUT_FILE_1" ] && [ -f "$INPUT_FILE_2" ]; then
        metaphlan "$INPUT_FILE_1","$INPUT_FILE_2" \
                  --bowtie2out "/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/test_gz/SRR5665009/SRR5665009_clean_final_metagenome.bowtie2.bz2" \
                  --input_type fastq --nproc $CPUS \
                  --sample_id $SRR_ID \
                  -t rel_ab_w_read_stats \
                  -o "/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/test_gz/SRR5665009/SRR5665009_clean_final_kneaddata_profile.txt"
    else
        echo "Paired files not found: $INPUT_FILE_1 or $INPUT_FILE_2"
    fi
}


export -f metaphlan_paired_end_srr_id


echo "$SRR_ID"

# Run process_srr_id sequentially for each SRR_ID

metaphlan_paired_end_srr_id $SRR_ID





# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"