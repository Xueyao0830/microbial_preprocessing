#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J PRJEB37017_compress
#SBATCH -t 3:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/PRJEB37017_compress_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/PRJEB37017_compress_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xueyao.wang@ki.se

source ~/.bashrc

module load parallel/20181122-nsc1

BIOPROJECT="PRJEB10878"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"

# Find all FASTQ files and compress them using parallel
find "$OUTPUT_DIR" -name "*.fastq" | parallel -j $CPUS gzip

# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"
