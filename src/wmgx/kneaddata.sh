#!/bin/bash
#SBATCH -A naiss2024-5-204
#SBATCH -J 37017_kneaddata
#SBATCH -t 150:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem=300G
#SBATCH -o /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/37017_kneaddata_%j.log
#SBATCH -e /proj/naiss2024-6-169/users/x_xwang/project/mm_network/log/metagenomic/37017_kneaddata_%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=xueyao.wang@ki.se

source ~/.bashrc
conda activate mm_crc

module load Java/1.8.0_181-nsc1-bdist
module load parallel/20181122-nsc1


# Define and export necessary paths
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/Trimmomatic-0.39
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin
export PATH=$PATH:/proj/naiss2024-6-169/users/x_xwang/bin/FastQC


source ~/.bashrc

BIOPROJECT="PRJEB10878"
INPUT_FASTQ_DIR="/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/$BIOPROJECT"
REFERENCE_DB="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db/GRCh38_genomic"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"
META_CSV_FILE="/proj/naiss2024-6-169/users/x_xwang/data/metadata/$BIOPROJECT/${BIOPROJECT}_runinfo.txt"
CPUS=20

# Logging start time
start_time=$(date +%s)
echo "Job started at: $(date)"


# Extract SRR IDs and Library Layouts from the CSV file
SRR_IDS_AND_LAYOUTS=$(awk -F, 'NR>1 {print $1, $16}' "$META_CSV_FILE")  # Adjust the column number for "Library Layout"


# Function to process single-end SRR ID
process_single_end_srr_id() {
    local SRR_ID=$1
    mkdir -p $OUTPUT_DIR/${SRR_ID}
    kneaddata --unpaired $INPUT_FASTQ_DIR/${SRR_ID}_1_clean_final.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_index \
              --output $OUTPUT_DIR/${SRR_ID}
        # Find the resulting FASTQ files in the output directory and gzip them
    for file in $OUTPUT_DIR/${SRR_ID}/*.fastq; do
        if [ -f "$file" ]; then
            gzip "$file"
        fi
    done

}

# Function to process paired-end SRR ID
process_paired_end_srr_id() {
    local SRR_ID=$1
    mkdir -p $OUTPUT_DIR/${SRR_ID}
    kneaddata --input1 $INPUT_FASTQ_DIR/${SRR_ID}_1_clean_final.fastq.gz \
              --input2 $INPUT_FASTQ_DIR/${SRR_ID}_2_clean_final.fastq.gz \
              --reference-db $REFERENCE_DB/GRCh38_index \
              --output $OUTPUT_DIR/${SRR_ID}
    for file in $OUTPUT_DIR/${SRR_ID}/*.fastq; do
        if [ -f "$file" ]; then
            gzip "$file"
        fi
    done

}

# Function to check and process SRR ID
process_srr_id() {
    local SRR_ID=$1
    local LAYOUT=$2
    if [ "$LAYOUT" == "PAIRED" ]; then
        echo "Processing paired-end SRR ID: $SRR_ID"
        process_paired_end_srr_id $SRR_ID
    else
        echo "Processing single-end SRR ID: $SRR_ID"
        process_single_end_srr_id $SRR_ID
    fi
}

# Function to check if final output files were created
check_output() {
    local SRR_ID=$1
    if ! grep -q "Final output files created" $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata.log 2>/dev/null; then
        echo $SRR_ID
    fi
}

# Export functions for use with parallel
export -f process_single_end_srr_id
export -f process_paired_end_srr_id
export -f process_srr_id
export -f check_output

# Check each SRR ID for completion and re-process if needed
SRR_TO_REPROCESS=$(echo "$SRR_IDS_AND_LAYOUTS" | while read SRR_ID LAYOUT; do
    check_output $SRR_ID
done)

if [ -n "$SRR_TO_REPROCESS" ]; then
    echo "Reprocessing SRR IDs: $SRR_TO_REPROCESS"
    echo "$SRR_IDS_AND_LAYOUTS" | while read SRR_ID LAYOUT; do
        if echo "$SRR_TO_REPROCESS" | grep -q "$SRR_ID"; then
            process_srr_id $SRR_ID $LAYOUT
        fi
    done
else
    echo "All SRR IDs processed successfully."
fi


FASTQC_OUTPUT_DIR="$OUTPUT_DIR/fastqc_kneaddata"
MULTIQC_OUTPUT_DIR="$OUTPUT_DIR/multiqc_output_kneaddata"

# Create output directories if they do not exist
mkdir -p $FASTQC_OUTPUT_DIR
mkdir -p $MULTIQC_OUTPUT_DIR

# Generate kneaddata read count table for all processed SRR IDs
for SRR_ID in $SRR_IDS; do
    kneaddata_read_count_table --input $OUTPUT_DIR/${SRR_ID} --output $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_clean_kneaddata_read_count_table.tsv

done

# Initialize the output file and write the header
head -n 1 $(find $OUTPUT_DIR -name "*_clean_kneaddata_read_count_table.tsv" | head -n 1) > $MERGED_CSV_FILE

# Loop through the files and append them to the output file
find $OUTPUT_DIR -name "*_clean_kneaddata_read_count_table.tsv" | while read file; do
    tail -n +2 $file >> $MERGED_CSV_FILE
done

echo "Merged $(find $OUTPUT_DIR -name "*_clean_kneaddata_read_count_table.tsv" | wc -l) files into $MERGED_CSV_FILE"


# Run FastQC on all processed files

#fastqc $OUTPUT_DIR/kneaddataOutput/*/*_kneaddata.fastq -o $FASTQC_OUTPUT_DIR

fastqc_single_end_srr_id() {
    local SRR_ID=$1
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata.fastq.gz -o $FASTQC_OUTPUT_DIR 
}

fastqc_paired_end_srr_id() {
    local SRR_ID=$1
    fastqc $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata_paired_1.fastq.gz $OUTPUT_DIR/${SRR_ID}/${SRR_ID}_1_clean_final_kneaddata_paired_2.fastq.gz -o $FASTQC_OUTPUT_DIR 
}

fastqc_srr_id() {
    local SRR_ID=$1
    if [ -f ${INPUT_FASTQ_DIR}/${SRR_ID}_2_clean_final.fastq.gz ]; then
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
#echo $SRR_IDS | tr ' ' '\n' | parallel -j $CPUS fastqc_srr_id {}

# Run FastQC for each SRR_ID
echo "$SRR_IDS_AND_LAYOUTS" | while read SRR_ID LAYOUT; do
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
#WORK_DIR="/proj/naiss2024-6-169/users/x_xwang/project/microbiota_crc/src"
#
#
#
#JOB_SCRIPT_TEMPLATE="$WORK_DIR/metaphlan.sh"  # Template script for individual jobs
#
## Create a unique job script for each BioProject
#JOB_SCRIPT="$WORK_DIR/${BIOPROJECT}_metaphlan_tmp.sh"
#cp "$JOB_SCRIPT_TEMPLATE" "$JOB_SCRIPT"
## Replace placeholders in the job script with actual values
#sed -i "s|BIOPROJECT_PLACEHOLDER|$BIOPROJECT|g" "$JOB_SCRIPT"
## Submit the job
#bash "$JOB_SCRIPT"
#echo "Submitted job for metaphlan of BioProject $BIOPROJECT."
## Remove the job script after submission
#rm "$JOB_SCRIPT"




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











