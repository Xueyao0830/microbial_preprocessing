1. download
2. subfolder - sample subfolder
2. awk wgs
3. biobakery
4. merge-biobakery



octapus

#1. spades to assemble contigs from metagenomic reads:
`TMP_DIR="/cfs/klemming/home/x/xueyaw/xueyao/tmp"`

`TEST_DIR="/cfs/klemming/home/x/xueyaw/xueyao/bin/SPAdes-4.0.0-Linux/bin/spades_test"`

`metaspades.py -1 sample_R1.fastq.gz -2 sample_R2.fastq.gz -o assembly_output/`

`./metaspades.py -s $TMP_DIR/spades/input/SRR8729931.fastq.gz -o $TMP_DIR/spades/output_unpaired`





#2. prokka or operon finder to predict genes and operons:
`prokka --outdir annotation_output --prefix sample --cpus 8 assembly_output/contigs.fasta`

`prokka --outdir $TMP_DIR/prokka/output --prefix sample --cpus 8 $TMP_DIR/spades/output/contigs.fasta`

`prokka --outdir $TMP_DIR/prokka/output_test --prefix sample --cpus 8 $TEST_DIR/contigs.fasta`

#3. detect operons, ppanggolin is the best

`operon_finder -i annotation_output/sample.gbk -o operon_output/
`

`operon_finder -i annotation_output/sample.gbk -o operon_output/
`
`ppanggolin workflow -f annotation_output/sample.gff -o ppanggolin_output/`

sample_name    $TMP_DIR/prokka/output_test/sample.gff 

`ppanggolin workflow --anno $TMP_DIR/ppanggolin/input/genomes_list.tsv -o $TMP_DIR/ppanggolin/output_test`