#!/bin/bash
#SBATCH -A naiss2024-5-709
#SBATCH -J merge_PRJNA731589
#SBATCH --partition=main
#SBATCH -t 5:30:00  # 4 hours, adjust if needed
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH -o /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.log
#SBATCH -e /cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/PRJNA731589/log/%x_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=xueyao.wang@ki.se


source /cfs/klemming/home/x/xueyaw/xueyao/miniconda/etc/profile.d/conda.sh
conda activate biobakery_env

BIOPROJECT="PRJNA526861"
BASE_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/2_biobakery_output_array"
MERGED_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/3_biobakery_merged"
TMP_DIR="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/tmp"
TMP_MERGED_HUMANN_genefamilies_relab="${TMP_DIR}/MERGED_HUMANN_genefamilies_relab/"
TMP_MERGED_HUMANN_genefamilies_rpk="${TMP_DIR}/MERGED_HUMANN_genefamilies_rpk/"
TMP_MERGED_HUMANN_pathabundance_rpk="${TMP_DIR}/MERGED_HUMANN_pathabundance_rpk"
TMP_MERGED_HUMANN_pathabundance_relab="${TMP_DIR}/MERGED_pathabundance_relab/"

LOG_FILE="$MERGED_DIR/merge.log"
# Temporary files to store merged outputs
MERGED_KNEADDATA="${MERGED_DIR}/${BIOPROJECT}_kneaddata_read_count_table_merged.tsv"

MERGED_METAPHLAN_COUNTS="${MERGED_DIR}/${BIOPROJECT}_metaphlan_species_counts_table.tsv"
MERGED_METAPHLAN_TAXO="${MERGED_DIR}/${BIOPROJECT}_metaphlan_taxonomic_profiles.tsv"
SRC_UTILS="/cfs/klemming/home/x/xueyaw/xueyao/project/mm_network_tetralith/mm_network/src/metagenomics/utils"


SELECTED_SAMPLES="${MERGED_DIR}/selected_samples.txt"



MERGED_HUMANN_genefamilies_rpk="${MERGED_DIR}/humann_rpk/${BIOPROJECT}_genefamilies_rpk.tsv"
MERGED_HUMANN_genefamilies_relab="${MERGED_DIR}/humann_relab/${BIOPROJECT}_genefamilies_relab.tsv"
MERGED_HUMANN_genefamilies_cpm="${MERGED_DIR}/humann_cpm/${BIOPROJECT}_genefamilies_cpm.tsv"

MERGED_HUMANN_pathabundance_relab="${MERGED_DIR}/humann_relab/${BIOPROJECT}_pathabundance_relab.tsv"
MERGED_HUMANN_pathabundance_rpk="${MERGED_DIR}/humann_rpk/${BIOPROJECT}_pathabundance_rpk.tsv"

# Input and output files
INPUT_RUNINFO="/cfs/klemming/home/x/xueyaw/xueyao/data/metagenomics/$BIOPROJECT/0_metadata/${BIOPROJECT}_runinfo.txt"
OUTPUT_RUNINFO="$MERGED_DIR/filtered_runinfo.txt"



mkdir -p $MERGED_DIR
touch $LOG_FILE

# Create directories
mkdir -p "${MERGED_DIR}/humann_rpk"
mkdir -p "${MERGED_DIR}/humann_relab"
mkdir -p "${MERGED_DIR}/humann_cpm"

mkdir -p $TMP_MERGED_HUMANN_genefamilies_relab
mkdir -p $TMP_MERGED_HUMANN_genefamilies_rpk
mkdir -p $TMP_MERGED_HUMANN_pathabundance_rpk
mkdir -p $TMP_MERGED_HUMANN_pathabundance_relab




# Temporary file to store selected samples
SELECTED_SAMPLES="${MERGED_DIR}/selected_samples.txt"
> "$SELECTED_SAMPLES"


# Count initial number of samples
INITIAL_SAMPLE_COUNT=$(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)

# Initialize header flag
HEADER_PRINTED=false
METAPHLAN_HEADER_PRINTED=false
SELECTED_COUNT=0  # Count the number of selected samples


# Get header from the first valid kneaddata file
HEADER_ADDED=false 

for SAMPLE_DIR in "$BASE_DIR"/*/; do
    SAMPLE_ID=$(basename "$SAMPLE_DIR")
    KNEADDATA_TABLE="${SAMPLE_DIR}/kneaddata/merged/kneaddata_read_count_table.tsv"
    
    if [ -f "$KNEADDATA_TABLE" ]; then
        # Get the last column value (final single)
        LAST_COLUMN_VALUE=$(awk 'NR>1 {print $(NF)}' "$KNEADDATA_TABLE" | tail -n 1)
        
        if (( $(echo "$LAST_COLUMN_VALUE > 10000" | bc -l) )); then
            echo "$SAMPLE_ID" >> "$SELECTED_SAMPLES"

            # Add header once
            if [ "$HEADER_ADDED" = false ]; then
                head -n 1 "$KNEADDATA_TABLE" > "$MERGED_KNEADDATA"
                HEADER_ADDED=true
            fi

            # Append selected sample data (keeping original headers)
            tail -n +2 "$KNEADDATA_TABLE" >> "$MERGED_KNEADDATA"
        fi
    fi
done

# Count initial and final samples
INITIAL_COUNT=$(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
FINAL_COUNT=$(wc -l < "$SELECTED_SAMPLES")

echo "Initial samples: $INITIAL_COUNT" > "$MERGED_DIR/sample_counts.txt"
echo "Final selected samples: $FINAL_COUNT" >> "$MERGED_DIR/sample_counts.txt"

# Merge Metaphlan species counts table by rows
HEADER_ADDED=false

for SAMPLE_DIR in "$BASE_DIR"/*/; do
    SAMPLE_ID=$(basename "$SAMPLE_DIR")
    METAPHLAN_TABLE="${SAMPLE_DIR}/metaphlan/merged/metaphlan_species_counts_table.tsv"

    if [ -f "$METAPHLAN_TABLE" ]; then
        if [ "$HEADER_ADDED" = false ]; then
            head -n 1 "$METAPHLAN_TABLE" > "$MERGED_METAPHLAN_COUNTS"
            HEADER_ADDED=true
        fi

        tail -n +2 "$METAPHLAN_TABLE" >> "$MERGED_METAPHLAN_COUNTS"
    fi
done

echo "Merging completed. Results saved in $MERGED_DIR"
# Read selected samples
mapfile -t SAMPLES < "$SELECTED_SAMPLES"



# Extract and write the header to the output file
head -n 1 "$INPUT_RUNINFO" > "$OUTPUT_RUNINFO"

# Create a grep pattern from sample IDs
grep_pattern=$(printf "%s\n" "${SAMPLES[@]}" | paste -sd'|' -)

# Append filtered lines to the output file
grep -E "^($grep_pattern)," "$INPUT_RUNINFO" >> "$OUTPUT_RUNINFO"

echo "Filtered runinfo saved to $OUTPUT_RUNINFO"



############################## metaphlan ##############

METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS=""

# Loop through selected samples and collect metaphlan taxonomic profile paths
while read -r SAMPLE_ID; do
    METAPHLAN_TABLE="${BASE_DIR}/${SAMPLE_ID}/metaphlan/merged/metaphlan_taxonomic_profiles.tsv"
    
    #echo $METAPHLAN_TABLE


    if [ -f "$METAPHLAN_TABLE" ]; then
        METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS="${METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS:+$METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS }$METAPHLAN_TABLE"

    else
        echo "⚠️ Warning: MetaPhlAn table missing for sample $SAMPLE_ID"
    fi
done < "$SELECTED_SAMPLES"

# Ensure there are files to merge
if [ -z "$METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS" ]; then
    echo "❌ No valid MetaPhlAn taxonomic profile tables found. Exiting..."
    exit 1
fi

# Run the Python script to merge taxonomic profiles
echo "🔄 Merging MetaPhlAn taxonomic profiles..."
python "$SRC_UTILS/merge_metaphlan_tables.py" $METAPHLAN_ABSOLUTE_ABUNDANCE_OUTPUTS > "${MERGED_DIR}/${BIOPROJECT}_metaphlan_taxonomic_profiles.tsv"

echo "✅ Merging complete: ${MERGED_DIR}/${BIOPROJECT}_metaphlan_taxonomic_profiles.tsv"



############################### humann ########################
# Process each selected sample
while read -r SAMPLE_ID; do
    
    cp $BASE_DIR/${SAMPLE_ID}/humann/merged/genefamilies.tsv  $TMP_MERGED_HUMANN_genefamilies_rpk
    cp $BASE_DIR/${SAMPLE_ID}/humann/merged/genefamilies_relab.tsv  $TMP_MERGED_HUMANN_genefamilies_relab
    cp $BASE_DIR/${SAMPLE_ID}/humann/merged/pathabundance.tsv  $TMP_MERGED_HUMANN_pathabundance_rpk
    cp $BASE_DIR/${SAMPLE_ID}/humann/merged/pathabundance_relab.tsv  $TMP_MERGED_HUMANN_pathabundance_relab


done < "$SELECTED_SAMPLES"

# Join HUMAnN tables
humann_join_tables --input "$TMP_MERGED_HUMANN_genefamilies_rpk" --output "$MERGED_HUMANN_genefamilies_rpk"
humann_join_tables --input "$TMP_MERGED_HUMANN_genefamilies_relab" --output "$MERGED_HUMANN_genefamilies_relab"
humann_join_tables --input "$TMP_MERGED_HUMANN_pathabundance_rpk" --output "$MERGED_HUMANN_pathabundance_rpk"
humann_join_tables --input "$TMP_MERGED_HUMANN_pathabundance_relab" --output "$MERGED_HUMANN_pathabundance_relab"

# Generate CPM file
if [ ! -f "$MERGED_HUMANN_genefamilies_cpm" ]; then
    humann_renorm_table --input "$MERGED_HUMANN_genefamilies_rpk" --units cpm --output "$MERGED_HUMANN_genefamilies_cpm"
fi

# Ensure CPM file exists
if [ ! -f "$MERGED_HUMANN_genefamilies_cpm" ]; then
    echo "❌ Error: CPM file not created successfully!"
    exit 1
fi

# Define groups and renaming schemes
declare -A groups=(
    ["uniref90_rxn"]="metacyc-rxn"
    ["uniref50_rxn"]="metacyc-rxn"
    ["uniref90_ko"]="kegg-orthology kegg-pathway kegg-module"
    ["uniref50_ko"]="kegg-orthology kegg-pathway kegg-module"
    ["uniref90_level4ec"]="ec"
    ["uniref50_level4ec"]="ec"
    ["uniref90_eggnog"]="eggnog"
    ["uniref50_eggnog"]="eggnog"
    ["uniref90_go"]="go infogo1000"
    ["uniref50_go"]="go infogo1000"
    ["uniref90_pfam"]="pfam"
    ["uniref50_pfam"]="pfam"
)

# Process each normalization type (_rpk, _relab, _cpm)
for norm in "rpk" "relab" "cpm"; do
    INPUT_FILE="${MERGED_DIR}/humann_${norm}/${BIOPROJECT}_genefamilies_${norm}"

    # Skip if input file is missing
    if [ ! -f "${INPUT_FILE}.tsv" ]; then
        echo "❌ Error: Missing ${INPUT_FILE}.tsv, skipping..."
        continue
    fi

    humann_rename_table --input "${INPUT_FILE}.tsv" --names uniref90 --output "${INPUT_FILE}_rename.tsv"

    for group in "${!groups[@]}"; do
        OUTPUT_BASE="${MERGED_DIR}/humann_${norm}/${BIOPROJECT}_${group}_${norm}"

        # Regroup the table
        humann_regroup_table --input "${INPUT_FILE}.tsv" --groups "$group" --output "${OUTPUT_BASE}.tsv"

        if [ $? -ne 0 ]; then
            echo "⚠️ Warning: Regrouping failed for ${OUTPUT_BASE}.tsv, skipping..."
            continue
        fi

        # Rename outputs
        for rename in ${groups[$group]}; do
            humann_rename_table --input "${OUTPUT_BASE}.tsv" --names "$rename" --output "${OUTPUT_BASE}_rename.tsv"
        done
    done
done







