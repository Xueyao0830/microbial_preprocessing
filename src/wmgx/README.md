# microbiota_crc

## requirement
conda env name: mm_crc

`kneaddata`

1. Trimmomatic (version == 0.33) (automatically installed)
2. Bowtie2 (version >= 2.2) (automatically installed)
3. Python (version >= 2.7)
4. Java Runtime Environment
5. TRF (optional)
6. Fastqc (optional)
7. SAMTools (only required if input file is in BAM format)
8. kraken2

## 1. Metagenomics processing pipeline

### 1.qulity control
`kneaddata`: KneadData is a tool designed to perform quality control on metagenomic sequencing data, especially data from microbiome experiments.



#### 1. contaminant removal

```
bowtie2-build GCF_000001405.26_GRCh38_genomic.fna GRCh38_index
```
1. human reference database: [Genome Reference Consortium Human Reference 38](https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.26/)

2. 




##### 1. Single End Reads
```
kneaddata --unpaired input/singleEnd.fastq --reference-db input/demo_db --output kneaddataOutputSingleEnd
```

##### kneaddata count table: 

generates the summary report of all the fastq files in the output folder

```
kneaddata_read_count_table --input kneaddataOutputSingleEnd --output kneaddata_read_count_table.tsv
```

##### 2 Paired End Reads
For paired end reads, we have to provide the forward and reverse reads for all sequences which are stored in 2 files.

```
kneaddata --input1 input/seq1.fastq --input2 input/seq2.fastq --reference-db input/demo_db --output kneaddataOutputPairedEnd 
```


### 3. adapters and low-quality sequences

#### check with FastQC

take a look at the QC scores for reads before and after clean-up i.e. trimming.

```
kneaddata --unpaired input/SE_extra.fastq --reference-db input/demo_db --output kneaddataOutputFastQC --run-fastqc-start --run-fastqc-end
```

#### automated quality control with Multiqc
```
multiqc /path/to/fastqc_output_dir
```

### 4. Absolute Read Counts
10,000 reads: Some studies use this as a minimum threshold to ensure enough coverage for reliable downstream analysis.

after removing the low counts experiments, merge them together 

more to reads: https://forum.qiime2.org/t/sufficient-number-of-reads-in-a-sample-for-an-analysis/13249/4

### 4. taxonomic classification and species abundances estimation


#### 1. `GTDB(V207)` (https://github.com/hcdenbakker/GTDB_Kraken?tab=readme-ov-file)
We will use Kraken2 as opposed to the popular MetaPhlAn3 due to the availability of GTDB reference databases suitable for Kraken2

[kraken2](https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown): it is a taxonomic sequence classifier that assigns taxonomic labels to DNA sequences. Kraken examines the -mers within a query sequence and uses the information within those -mers to query a database. That database maps -mers to the lowest common ancestor (LCA) of all genomes known to contain a given -mer.

build the kraken2 database()
```
kraken2-build --download-taxonomy --db /path/to/kraken2_GTDB
kraken2-build --add-to-library /path/to/extracted/bac120_marker_genes_all --db /path/to/kraken2_GTDB
kraken2-build --add-to-library /path/to/extracted/ar53_marker_genes_all --db /path/to/kraken2_GTDB
kraken2-build --build --db /path/to/kraken2_GTDB
```


```
# Run kraken2
kraken2 --db $kraken2_GTDB --output "$output".krkn --use-names --report "$output".rep --gzip-compressed --paired --memory-mapping "$input"_1.filtered.fastq.gz "$input"_2.filtered.fastq.gz 
# Run bracken - species abundances
​bracken -i "$output".rep -o "$output".brkn.sp -d $bracken_GTDB -l S
# Run bracken - genera abundances
​bracken -i "$output".rep -o "$output".brkn.ge -d $bracken_GTDB -l G

```

#### 2. `MetaPhlAn4`

#### 3. `Humann`
1. metaphlan: taxonomy
2. chocophlan: nucleotide-level mapping, to map reads to known microbial genomes. link microbial taxa to their gene families.
3. metacyc: a comprehensive database of metabolic pathways. After chocophlan, it uses metacyc to map those genes to metabolic pathways to provide the functional context, to annotate the functional capabilities of the microbial community by linking gene families to metabolic pathways.





obtain raw fastq files and applied quality filtering, adapter trimming and deduplication using [fastp 0.23.4](https://github.com/OpenGene/fastp)

```
fastp --in1 $FASTQ_FWD --in2 $FASTQ_REV --length_required 60 --dedup --thread $N_THREADS --out1 $FASTQ_FWD_CLEAN --out2 $FASTQ_REV_CLEAN
```
### 1. using GTDB database
this datasets collection includes only microbiome data from whole genome shotgun sequencing. We reprocessed raw data using several computational tools and using the Genome Taxonomy Database [GTDB v207](https://gtdb.ecogenomic.org/) as the reference database, as it is specifically designed to provide consistent and comprehensive taxonomy for bacterial genomes.


merge paired reads

if paired-end reads could not be merged, concatenated forward and reverse reads into a single fastq file.

```
# Quality filtering, adapter trimming, and deduplication using fastp
fastp --in1 $FASTQ_FWD --in2 $FASTQ_REV --length_required 60 --dedup --thread $N_THREADS --out1 $FASTQ_FWD_CLEAN --out2 $FASTQ_REV_CLEAN

# Merge paired-end reads using flash2
flash2 -o merged_reads -z -t $N_THREADS -M 200 $FASTQ_FWD_CLEAN $FASTQ_REV_CLEAN

# Concatenate unmerged reads
cat merged_reads.notCombined_1.fastq merged_reads.notCombined_2.fastq > unmerged.fastq

# Concatenate merged reads with unmerged reads if desired
cat merged_reads.extendedFrags.fastq unmerged.fastq > combined_reads.fastq
```



##### 2. filter out host DNA
then filter out host DNA using [bowtie 2.5.4], aligning reads to the human reference genome named [Genome Reference Consortium human build 38](https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.26/)

```
bowtie2 -U $FASTQ_CONCAT -x $HOST_REF --sensitive -U - | samtools fastq -f 4 -c 9 - | gzip > $output
```
### 2. using the bowtie2 database (https://huttenhower.sph.harvard.edu/kneaddata)



#### 2. `MetaPhlAn4.0` (https://github.com/biobakery/biobakery/wiki/metaphlan4)

[metaphlan_databases](http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/)

The viral sequence database used in the MetaPhlan 4 viral module and described by Moreno et al. (2024)
The SGB database described by Pasolli et al. (2019) 

```
metaphlan SRS014476-Supragingival_plaque.fasta.gz --input_type fastq --bowtie2out metagenome.bowtie2.bz2 --nproc 4 -t rel_ab_w_read_stats --sample_id $SRUN_ID -o profiled_metagenome.txt
```
MetaPhlAn can also natively handle paired-end metagenomes (but does not use the paired-end information), and, more generally, metagenomes stored in multiple files (but you need to specify the --bowtie2out parameter):

```
metaphlan metagenome_1.fastq,metagenome_2.fastq --bowtie2out metagenome.bowtie2.bz2 --nproc 20 --input_type fastq -t rel_ab_w_read_stats -o profiled_metagenome.txt
```

```
for i in SRS*.fasta.gz; do metaphlan $i --input_type fasta --nproc 4 > ${i%.fasta.gz}_profile.txt; done
```
##### merge metaphlan profiles

[relative abundance]

[path]:/proj/naiss2024-6-169/users/x_xwang/bin/MetaPhlAn/metaphlan/utils
```
merge_metaphlan_tables.py *_profile.txt > merged_abundance_table.txt
```
[absolute abundance]
merge_metaphlan_table_absolute.py *_profile.txt > merged_abundance_table.txt

##### Re-profiling a sample using its bowtie2out file
When re-analyzing a sample (e.g. using different MetaPhlAn options), it is preferable to start from the sample's `.bowtie2out.txt` file. This allows you to skip the time-consuming step of mapping the sample's reads to the marker gene database, making the re-analysis much faster.
















Then an estimate could probably be made, but what do you want to use it for? To determine how "deep" you need to sequence your samples? It also depends on how high host content your samples may have, for example fecal samples have almost no human DNA in them, so they are very cost-effective to sequence as most DNA you get out is directly microbial. Saliva is worse because it can vary quite a lot from sample to sample how much host content there is, but they are nowhere near as bad as vaginal in this regard. In the end, it also depends on what you want to do with the data (all numbers here assume all reads are microbial DNA--so must be adjusted depending on the host content):

    Are you mainly interested in taxonomic profiling, then you don't need very high depth at all, a couple of million reads is enough for most environments, but standard practice seems to be either a shallow approach with about 2-3 million reads, or a normal depth with about 20-30 million reads (probably in large due to HiSeq Illumina machines from 10 years ago being able to reasonably cost-effectively produce data for a resonable amount of samples at once on a single flowcell at this depth)
    If you want to be able to produce metagenome-assembled genomes (MAGs), you probably need at least 20-30 million reads for a reasonably complex microbiome, but note that you will not get any high quality reference genomes out of this. They will be fragmented and in some cases incomplete.
    If you're looking for specific pathways or want to investigate specific low-abundance genes of interest (e.g. antibiotic resistance genes or maybe something even more rare) you may need even higher depth; but then directed sequencing/detection methods may also be interesting to consider


3. kraken2 ncbi database (https://github.com/R-Wright-1/kraken_metaphlan_comparison/wiki/Downloading-databases) (https://github.com/R-Wright-1/kraken_metaphlan_comparison/wiki)


## sunbeam pipeline: (https://github.com/sunbeam-labs/sunbeam)

## biobakery_workflows(https://github.com/biobakery/biobakery_workflows)






