#!/bin/bash
BIOPROJECT="PRJNA731589"
# Define paths
OUTPUT_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output_array"
LOG_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/log"
RESUBMIT_SCRIPT="/cfs/klemming/home/x/xueyaw/xueyao/tmp/resubmit_biobakery.sh"

# Initialize an empty array for unfinished samples
REMAINING_JOBS=()

# Loop through each subdirectory in the output directory
for SAMPLE_DIR in "$OUTPUT_DIR"/*; do
    if [ -d "$SAMPLE_DIR" ]; then  # Check if it's a directory
        SAMPLE_NAME=$(basename "$SAMPLE_DIR")
        FLAG_FILE="$SAMPLE_DIR/completion_flag.txt"

        # Check if the completion flag exists
        if [ ! -f "$FLAG_FILE" ]; then
            echo "❌ Sample $SAMPLE_NAME is NOT complete. Adding to resubmission list."
            REMAINING_JOBS+=("$SAMPLE_NAME")
        else
            echo "✅ Sample $SAMPLE_NAME is complete."
        fi
    fi
done

# If all samples are completed, create all_completion_flag.txt
if [ ${#REMAINING_JOBS[@]} -eq 0 ]; then
    touch "$OUTPUT_DIR/all_completion_flag.txt"
    echo "🎉 All samples are completed! Created all_completion_flag.txt."
    exit 0
fi

# If there are remaining jobs, create and submit a new SLURM array job
echo "🔄 Resubmitting ${#REMAINING_JOBS[@]} unfinished samples..."

echo "#!/bin/bash" > "$RESUBMIT_SCRIPT"
echo "#SBATCH -A naiss2024-5-709" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH -J bakery_resubmit" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH --partition=main" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH -t 10:00:00" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH --cpus-per-task=16" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH --mem=128G" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH --array=0-$(( ${#REMAINING_JOBS[@]} - 1 ))" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH -o $LOG_DIR/%x_%A_%a.log" >> "$RESUBMIT_SCRIPT"
echo "#SBATCH -e $LOG_DIR/%x_%A_%a.err" >> "$RESUBMIT_SCRIPT"

echo "source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh" >> "$RESUBMIT_SCRIPT"
echo "conda activate biobakery_env" >> "$RESUBMIT_SCRIPT"
echo "BIOPROJECT='$BIOPROJECT'" >> "$RESUBMIT_SCRIPT"
echo "INPUT_DIR='/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/1_1_raw/WGS_awk'" >> "$RESUBMIT_SCRIPT"
echo "OUTPUT_DIR='/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output_array'" >> "$RESUBMIT_SCRIPT"
echo "DATABASE_DIR='/cfs/klemming/home/x/xueyaw/xueyao/biobakery_workflows_databases'" >> "$RESUBMIT_SCRIPT"

echo "SAMPLES=(${REMAINING_JOBS[@]})" >> "$RESUBMIT_SCRIPT"
echo "SAMPLE_NAME=\${SAMPLES[\$SLURM_ARRAY_TASK_ID]}" >> "$RESUBMIT_SCRIPT"

cat "/cfs/klemming/home/x/xueyaw/xueyao/project/mm_network_tetralith/mm_network/src/metagenomics/workflow/2_2_1_resubmit.sh" >> "$RESUBMIT_SCRIPT"

#echo "bash /cfs/klemming/home/x/xueyaw/xueyao/project/mm_network_tetralith/mm_network/src/metagenomics/workflow/2_1_biobakery_array.sh \$SAMPLE_NAME" >> "$RESUBMIT_SCRIPT"

# Submit the new job
chmod +x "$RESUBMIT_SCRIPT"
sbatch "$RESUBMIT_SCRIPT"

echo "✅ Resubmission job has been submitted."
