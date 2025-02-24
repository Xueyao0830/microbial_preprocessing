#!/bin/bash


# Define the directory containing the TSV files
input_dir="/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics/PRJNA389927"
output_file="${input_dir}/PRJNA389927_clean_merged_kneaddata_read_counts.tsv"

# List all TSV files in the directory
tsv_files=$(ls ${input_dir}/*_clean_kneaddata_read_count_table.tsv)

# Initialize the output file and write the header
head -n 1 $(echo $tsv_files | awk '{print $1}') > $output_file

# Loop through the files and append them to the output file
for file in $tsv_files; do
    tail -n +2 $file >> $output_file
done

echo "Merged $(echo $tsv_files | wc -w) files into $output_file"