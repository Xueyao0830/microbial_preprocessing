#!/bin/bash
#module spider parallel/20230422
source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env


BIOPROJECT="PRJNA526861"
BASE_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/2_biobakery_output_array"
MERGED_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/3_biobakery_merged_tmp"
SRC_UTILS="/cfs/klemming/home/x/xueyaw/xueyao/project/mm_network_tetralith/mm_network/src/metagenomics/utils"

# Temporary file to store selected samples
SELECTED_SAMPLES="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA526861/3_biobakery_merged/selected_samples.txt"
mkdir -p $MERGED_DIR

humann_join_tables --input 