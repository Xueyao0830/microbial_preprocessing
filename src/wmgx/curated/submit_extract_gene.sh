#!/bin/bash
#SBATCH --mem=360G
#SBATCH --time=5:00:00
#SBATCH --account=naiss2024-5-204

module load Anaconda/2023.09-0-hpc1

module load R/4.2.2-hpc1-gcc-11.3.0-bare

Rscript /proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/curated/extract_gene_family.r /proj/naiss2024-6-169/users/x_xwang/project/mm_network/src/metagenomics/curated/unique_study_name.txt \
> /proj/naiss2024-6-169/users/x_xwang/data/metagenomics/curated/log/extract_data_gene_familu.log 2>&1
