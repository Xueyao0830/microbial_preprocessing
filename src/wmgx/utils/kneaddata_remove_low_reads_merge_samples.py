import pandas as pd
import argparse

def process_files(kneaddata_file, run_info_file, output_file):
    # Read the input files
    kneaddata_read_counts_csv = pd.read_csv(kneaddata_file, sep='\t')
    run_info_csv = pd.read_csv(run_info_file, sep=',')

    # Remove the substring from the 'Sample' column
    kneaddata_read_counts_csv['Sample'] = kneaddata_read_counts_csv['Sample'].str.replace('_1_WGS_clean_final_kneaddata', '', regex=False)
    kneaddata_read_counts_csv['Run'] = kneaddata_read_counts_csv['Sample']

    # Merge the dataframes on 'Run' column
    merged_df = pd.merge(kneaddata_read_counts_csv, run_info_csv[['Run', 'BioSample']], on='Run', how='left')

    # Filter rows where Finalpair1 and Finalpair2 are both greater than or equal to 10,000
    filtered_csv = merged_df[(merged_df['final pair1'] >= 10000) & (merged_df['final pair2'] >= 10000)]

    # Group by 'SampleName' and merge 'Run' values, separating them with commas
    grouped_csv = filtered_csv.groupby('BioSample').agg({
        'Run': lambda x: ','.join(x),
        'final pair1': 'first',  # Keep Finalpair1 and Finalpair2 as they are after filtering
        'final pair2': 'first'
    }).reset_index()

    # Rename columns to match the new CSV structure
    grouped_csv.rename(columns={
        'BioSample': 'sample_id',
        'Run': 'NCBI_accession'
    }, inplace=True)

    # Save the new CSV file
    grouped_csv.to_csv(output_file, index=False,sep='\t')

if __name__ == "__main__":
    # Set up argument parsing
    parser = argparse.ArgumentParser(description='Process kneaddata and run info CSV files.')
    parser.add_argument('kneaddata_file', help='Path to the kneaddata read counts TSV file.')
    parser.add_argument('run_info_file', help='Path to the run info CSV file.')
    parser.add_argument('output_file', help='Path to save the output CSV file.')

    # Parse the arguments
    args = parser.parse_args()

    # Run the processing function with provided arguments
    process_files(args.kneaddata_file, args.run_info_file, args.output_file)