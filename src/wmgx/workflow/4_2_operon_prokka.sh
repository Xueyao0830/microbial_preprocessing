#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J spades_PRJNA731589
#SBATCH --partition=main
#SBATCH -t 10:00:00  
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
INPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output_array"
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_operon/prokka/output"


#SAMPLES=($(ls -1 "$INPUT_DIR"))
SAMPLES=SRR14610570
mkdir -p $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/${SAMPLES}

prokka $TEST_DIR/contigs.fasta \
      --outdir $TMP_DIR/prokka/output_test \
       --prefix sample \
       --cpus 8 


if [ $? -eq 0 ]; then
    echo "✅ prokka completed for $SAMPLE"
else
    echo "❌ prokka failed for $SAMPLE" >&2
    exit 1
fi

### #####SBATCH --array=0-172

