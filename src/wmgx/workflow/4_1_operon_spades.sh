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
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_operon/"
OUTPUT_DIR_SPADES="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_operon/"
WORK_DIR="/cfs/klemming/home/x/xueyaw/xueyao/miniconda/envs/biobakery_env/bin"




#SAMPLES=($(ls -1 "$INPUT_DIR"))
SAMPLES=SRR14610570
mkdir -p $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/${SAMPLES}

repair.sh in1=$INPUT_DIR/$SAMPLES/kneaddata/main/${SAMPLES}_1.fastq.gz in2=$INPUT_DIR/$SAMPLES/kneaddata/main/${SAMPLES}_2.fastq.gz \
          out1=/cfs/klemming/home/x/xueyaw/xueyao/tmp/spades/paired_1.fastq.gz out2=/cfs/klemming/home/x/xueyaw/xueyao/tmp/spades/paired_2.fastq.gz outsingle=orphans.fastq.gz



$WORK_DIR/metaspades.py -1 $OUTPUT_DIR/${SAMPLES}/repaired/${SAMPLES}_1.fastq.gz \
            -2 $OUTPUT_DIR/${SAMPLES}/repaired/${SAMPLES}_2.fastq.gz \
            -o $OUTPUT_DIR/${SAMPLES}/spades \
            -k 21,33,55,77 \
            --threads 16 \
            --memory 128 \
            --cov-cutoff auto

prokka --outdir $OUTPUT_DIR/${SAMPLES}/prokka \
       --prefix sample \
       --metagenome \
       --cpus 16 \
       --fast \
       --force \
       --centre ABC \
       --compliant \
       $OUTPUT_DIR/${SAMPLES}/spades/contigs.fasta 

if [ $? -eq 0 ]; then
    echo "✅ metaSPAdes completed for $SAMPLE"
else
    echo "❌ metaSPAdes failed for $SAMPLE" >&2
    exit 1
fi

### #####SBATCH --array=0-172

