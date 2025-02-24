#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J process_demo
#SBATCH -t 2:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH --exclusive
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/log/process/BIOPROJECT_PLACEHOLDER_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/log/process/BIOPROJECT_PLACEHOLDER_%j.err

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist

module load parallel/20181122-nsc1

# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC

BIOPROJECT="test_process_clean"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics_clean/$BIOPROJECT"
CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"


# Extract SRR IDs from the input directory
SRR_IDS=$(ls $INPUT_FASTQ_DIR/*_{1,2}.fastq.gz | xargs -n 1 basename | cut -d '_' -f 1 | sort | uniq)


# Function to process single-end SRR ID
process_single_end_srr_id() {
    local SRR_ID=$1
    mkdir -p $OUTPUT_DIR/${SRR_ID}
    kneaddata --unpaired $INPUT_FASTQ_DIR/${SRR_ID}_1.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_index \
              --output $OUTPUT_DIR/${SRR_ID}
}

# Function to process paired-end SRR ID
process_paired_end_srr_id() {
    local SRR_ID=$1
    mkdir -p $OUTPUT_DIR/${SRR_ID}
    kneaddata --input1 $INPUT_FASTQ_DIR/${SRR_ID}_1.fastq.gz \
              --input2 $INPUT_FASTQ_DIR/${SRR_ID}_2.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_index \
              --output $OUTPUT_DIR/${SRR_ID}
}

# Function to check and process SRR ID
process_srr_id() {
    local SRR_ID=$1
    if [ -f ${INPUT_FASTQ_DIR}/${SRR_ID}_2.fastq.gz ]; then
        echo "Processing paired-end SRR ID: $SRR_ID"
        process_paired_end_srr_id $SRR_ID
    else
        echo "Processing single-end SRR ID: $SRR_ID"
        process_single_end_srr_id $SRR_ID
    fi
}

export -f process_single_end_srr_id
export -f process_paired_end_srr_id
export -f process_srr_id

# Run process_srr_id in parallel for each SRR_ID
for SRR_ID in $SRR_IDS; do
    process_srr_id $SRR_ID
done

FASTQC_OUTPUT_DIR="$OUTPUT_DIR/fastqc_kneaddata"
MULTIQC_OUTPUT_DIR="$OUTPUT_DIR/multiqc_output_kneaddata"

# Create output directories if they do not exist
mkdir -p $FASTQC_OUTPUT_DIR
mkdir -p $MULTIQC_OUTPUT_DIR

# Generate kneaddata read count table for all processed SRR IDs
for SRR_ID in $SRR_IDS; do
    kneaddata_read_count_table --input $OUTPUT_DIR/${SRR_ID} --output $OUTPUT_DIR/${SRR_ID}_kneaddata_read_count_table.tsv

done

# Run FastQC on all processed files

#fastqc $OUTPUT_DIR/kneaddataOutput/*/*_kneaddata.fastq -o $FASTQC_OUTPUT_DIR

fastqc_single_end_srr_id() {
    local SRR_ID=$1
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_kneaddata.fastq -o $FASTQC_OUTPUT_DIR 
}

fastqc_paired_end_srr_id() {
    local SRR_ID=$1
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_kneaddata_paired_1.fastq $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_kneaddata_paired_2.fastq -o $FASTQC_OUTPUT_DIR 
}

fastqc_srr_id() {
    local SRR_ID=$1
    if [ -f ${INPUT_FASTQ_DIR}/${SRR_ID}_2.fastq.gz ]; then
        echo "fastqc paired-end SRR ID: $SRR_ID"
        fastqc_paired_end_srr_id $SRR_ID
    else
        echo "fastqc single-end SRR ID: $SRR_ID"
        fastqc_single_end_srr_id $SRR_ID
    fi
}


export -f fastqc_single_end_srr_id
export -f fastqc_paired_end_srr_id
export -f fastqc_srr_id

echo $SRR_IDS 

# Run process_srr_id in parallel for each SRR_ID
for SRR_ID in $SRR_IDS; do
    fastqc_srr_id $SRR_ID
done

# Run MultiQC to aggregate FastQC results
multiqc $FASTQC_OUTPUT_DIR -o $MULTIQC_OUTPUT_DIR


# Logging end time and calculating running time
end_time=$(date +%s)
echo "Job ended at: $(date)"
runtime=$((end_time - start_time))
echo "Job running time: $runtime seconds"


# Print message indicating completion
echo "FastQC and MultiQC analysis complete. Check the MultiQC report at $MULTIQC_OUTPUT_DIR/multiqc_report.html"


###### call metaphlan.sh
# Define variables
WORK_DIR="/proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/src"



JOB_SCRIPT_TEMPLATE="$WORK_DIR/metaphlan.sh"  # Template script for individual jobs

# Create a unique job script for each BioProject
JOB_SCRIPT="$WORK_DIR/${BIOPROJECT}_metaphlan_tmp.sh"
cp "$JOB_SCRIPT_TEMPLATE" "$JOB_SCRIPT"
# Replace placeholders in the job script with actual values
sed -i "s|BIOPROJECT_PLACEHOLDER|$BIOPROJECT|g" "$JOB_SCRIPT"
# Submit the job
bash "$JOB_SCRIPT"
echo "Submitted job for metaphlan of BioProject $BIOPROJECT."
# Remove the job script after submission
rm "$JOB_SCRIPT"




# kneaddata count table
#kneaddata_read_count_table --input $OUTPUT_DIR/$SRR_ID/kneaddataOutputFastQC --output $OUTPUT_DIR/$SRR_ID/kneaddataOutputFastQC/kneaddata_read_count_table.tsv

#python $SRC_UTILS/merge_metaphlan_tables.py $OUTPUT_DIR/$SRR_ID/${SRR_ID}_kneaddata_profile.txt > $OUTPUT_DIR/merged_absolute_abundance_table.txt


#kneaddata --unpaired $INPUT_FASTQ_DIR/test_single/ERR1293057.fastq.gz --reference-db $REFERENCE_DB/GRCh38_index --output $INPUT_FASTQ_DIR/test_single/kneaddataOutputSingleEnd


# using FastQC
#kneaddata --unpaired $INPUT_FASTQ_DIR/${SRUN_ID}.fastq.gz --reference-db $REFERENCE_DB/GRCh38_index --output $INPUT_FASTQ_DIR/kneaddataOutputFastQC --run-fastqc-start --run-fastqc-end

# kneaddata count table
#kneaddata_read_count_table --input $INPUT_FASTQ_DIR/kneaddataOutputSingleEnd --output $INPUT_FASTQ_DIR/kneaddataOutputFastQC/kneaddata_read_count_table.tsv



#metaphlan $INPUT_FASTQ_DIR/kneaddataOutputFastQC/${SRUN_ID}_kneaddata.fastq --input_type fastq --nproc 16 > $OUTPUT_DIR/${SRUN_ID}_kneaddata_profile.txt


# loop

#for i in SRS*.fasta.gz; do metaphlan $i --input_type fasta --nproc 16 > ${i%.fasta.gz}_profile.txt; done







# paired end

#kneaddata --input1 $INPUT_FASTQ_DIR/test_paired/ERR1293937_1.fastq --input2 $INPUT_FASTQ_DIR/test_paired/ERR1293937_2.fastq --reference-db $REFERENCE_DB/GRCh38_index --output kneaddataOutputPairedEnd 

# using FastQC
#kneaddata --input1 $INPUT_FASTQ_DIR/test_paired/ERR1293937_1.fastq --input2 $INPUT_FASTQ_DIR/test_paired/ERR1293937_2.fastq --reference-db $REFERENCE_DB/GRCh38_index --output $INPUT_FASTQ_DIR/test_paired/kneaddataOutputFastQC --run-fastqc-start --run-fastqc-end





#metaphlan SRS014476-Supragingival_plaque.fastq --input_type fastq --nproc 4 > SRS014476-Supragingival_plaque_profile.txt


#for i in SRS*.fasta.gz; do metaphlan $i --input_type fasta --nproc 4 > ${i%.fasta.gz}_profile.txt; done











