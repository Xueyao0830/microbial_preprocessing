
# Create sample-specific output directory
SAMPLE_OUTPUT_DIR="$OUTPUT_DIR/$SAMPLE_NAME"
mkdir -p "$SAMPLE_OUTPUT_DIR"

# Skip if the sample is already completed
if [ -f "$SAMPLE_OUTPUT_DIR/completion_flag.txt" ]; then
    echo "✅ Sample $SAMPLE_NAME is already completed. Skipping..."
    exit 0
fi

# Run bioBakery Workflow for this sample
biobakery_workflows wmgx --input "$INPUT_DIR/$SAMPLE_NAME" --output "$SAMPLE_OUTPUT_DIR" \
    --contaminate-databases "$DATABASE_DIR/kneaddata_db_human_genome,$DATABASE_DIR/kneaddata_db_human_metatranscriptome,$DATABASE_DIR/kneaddata_db_rrna" \
    --threads 16 \
    --bypass-strain-profiling \
    --remove-intermediate-output \
    --qc-options "--run-fastqc-start --run-fastqc-end" 


# Check if the log file contains "INFO: AnADAMA run finished."
if grep -q "INFO: AnADAMA run finished." "$SAMPLE_OUTPUT_DIR/anadama.log"; then
    touch "$SAMPLE_OUTPUT_DIR/completion_flag.txt"
    echo "✅ Processing complete for sample: $SAMPLE_NAME"
else
    echo "❌ Processing failed for sample: $SAMPLE_NAME"
    exit 1
fi

