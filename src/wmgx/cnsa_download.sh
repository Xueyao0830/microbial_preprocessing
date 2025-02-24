#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J cnsa_download
#SBATCH -t 1:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=20
#SBATCH --mem=200G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/cnsa/%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/download/cnsa/%j.err

# Load necessary modules
module load parallel/20181122-nsc1  # Load GNU parallel

# Define variables
WORK_DIR="/proj/naiss2024-6-169/users/x_xwang/src"
DATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/cnsa"
BASE_URL="ftp://ftp.cngb.org/pub/CNSA/data5/CNP0004314/"

# Create necessary directories
mkdir -p $DATA_DIR
cd $DATA_DIR

# Fetch the list of directories and filter only fastq folders (starting with CNX) and exclude those starting with CNA
parallel -j 20 wget -c -nH -np -r -R "index.html*" --cut-dirs=5 -P $DATA_DIR ${BASE_URL}

echo "All fastq folders downloaded successfully."