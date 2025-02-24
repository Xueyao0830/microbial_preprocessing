#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J cnsa_download
#SBATCH --partition=main
#SBATCH -t 23:30:00  # 4 hours, adjust if needed
#SBATCH --cpus-per-task=32
#SBATCH --mem=512G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/CNP0004314/log/%j.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/CNP0004314/log/%j.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Define variables

DATA_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/CNP0004314"
BASE_URL="ftp://ftp.cngb.org/pub/CNSA/data5/CNP0004314/"

# Create necessary directories
mkdir -p $DATA_DIR
cd $DATA_DIR

# Fetch the list of directories and filter only fastq folders (starting with CNX) and exclude those starting with CNA
parallel -j 20 wget -c -nH -np -r -R "index.html*" --cut-dirs=5 -P $DATA_DIR ${BASE_URL}

echo "All fastq folders downloaded successfully."