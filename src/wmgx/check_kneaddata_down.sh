#!/bin/bash

# Define the base directory containing the subfolders
BIOPROJECT="PRJEB37017"
OUTPUT_DIR="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/$BIOPROJECT"


# Initialize a flag to track if all log files have "Final output files created"
all_done=true

# Loop through each subfolder and check the log file
for log_file in $(find "$BASE_DIR" -type f -name "*_kneaddata.log"); do
    if grep -q "Final output files created" "$log_file"; then
        echo "Log file $log_file: kneaddata completed."
    else
        echo "Log file $log_file: kneaddata not completed."
        all_done=false
    fi
done

# If all log files have the "Final output files created" message, echo "kneaddata done"
if $all_done; then
    echo "kneaddata done"
else
    echo "Not all kneaddata processes are completed."
fi