#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J gsa_download
#SBATCH -t 01:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16000
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/log/%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/log/%j.err

# Load necessary modules
module load parallel/20181122-nsc1  # Load GNU parallel

# Define variables
# Define variables


WORK_DIR="/proj/naiss2024-6-169/users/x_xwang/src"
DATA_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics"

# Create necessary directories
mkdir -p $DATA_DIR
cd $DATA_DIR

wget -r -np https://download.cncb.ac.cn/gsa/CRA005093/

