from Bio import SeqIO

#input_file = "/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics_new/test_paired/kneaddataOutput/ERR3986544/ERR3986544_1_kneaddata.fastq"
#input_file = "/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics_new/test_paired/kneaddataOutput/ERR710432/ERR710432_1_kneaddata_paired_1.fastq"
#input_file = "/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics_new/test_fastq_issue/test_fastq_issue/kneaddataOutput/ERR3986544/ERR3986544_1_kneaddata.fastq"
#input_file = "/proj/naiss2024-6-169/users/x_xwang/data/metagenomics/test_fastq_issue/ERR3986544_1.fastq"
input_file = "/proj/naiss2024-6-169/users/x_xwang/data/processed_metagenomics_new/test_fastq_issue/test_fastq_issue/SRR21876649_single/SRR21876649_kneaddata.fastq"
with open(input_file, "r") as handle:
    for record in SeqIO.QualityIO.FastqGeneralIterator(handle):
        if len(record[1]) != len(record[2]):
            print(f"Inconsistent read found: {record[0]}")
