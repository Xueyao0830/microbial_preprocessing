#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J prodigal_PRJNA731589
#SBATCH --partition=main
#SBATCH -t 5:00:00  
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se

# Load Conda environment
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

# Project directories
BIOPROJECT="PRJNA731589"

SAMPLES=SRR14610570

INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_operon/${SAMPLES}/spades"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_operon"
OUTPUT_prodigal_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_operon/${SAMPLES}/prodigal"
WORK_DIR="/cfs/klemming/home/x/xueyaw/xueyao/miniconda/envs/biobakery_env/bin"




#SAMPLES=($(ls -1 "$INPUT_DIR"))

mkdir -p $OUTPUT_prodigal_DIR

prodigal -i $INPUT_DIR/contigs.fasta -a $OUTPUT_prodigal_DIR/predicted_proteins.fasta -p meta
