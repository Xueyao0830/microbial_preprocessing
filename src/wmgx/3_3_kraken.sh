#!/bin/bash
#BSUB -W 8:00
#BSUB -M 120000
#BSUB -n 32
#BSUB -e /data/MMAC-Shared-Drive/scratch/%J.err
#BSUB -o /data/MMAC-Shared-Drive/scratch/%J.out


#Script to run kraken2 bracken pipeline for single-end reads


#notes: - program assumes fastq files residing in single folder (typically will be kneaddata_out folder)
#       - modify if have fasta or other file name (e.g., .fna, .fq, etc.)
#       - program assumes reads have already been quality filtered and trimmed to a min of 90bp
#       - if have shorter min read length then need to build and use bracken db built for shorter read length

#       - program generates k2 read mappings and bracken abundance estimation at the phylum, genus, and species levels
#       - modify if want output for other levels
#       - k2 confidence set to 0.1 and bracken threshold to t-10; consider modifying to reduce FPR as needed

#       - requesting 32 cores, 120G RAM, and 8 hr wall time; see: https://bmi.cchmc.org/resources/software/lsf-examples
#       - to run job: bsub < k2_bracken_pipeline_single_end.bat




#Navigate to folder containing fastq files: (CHANGE ME)
cd /proj/naiss2024-6-169/users/x_xwang/data/metagenomics/PRJNA961076/2_1_kneaddata/SRR24315709


#Load modules
module load kraken/2.0.8
module load bracken/2.5.0


#Classify reads with kraken2
mkdir k2_outputs
mkdir k2_reports

for i in ./*R1_kneaddata_paired_1.fastq
do
  filename=$(basename "$i")
  fname="${filename%_R1_kneaddata_paired_*.fastq}"
  kraken2 --db /data/MMAC-Shared-Drive/ref_databases/kraken/db_refseq_20200725 \
  --confidence 0.1 \
  --threads 32 \
  --use-names \
  --output k2_outputs/${fname}_output.txt \
  --report k2_reports/${fname}_report.txt \
  --paired ${fname}_R1_kneaddata_paired_1.fastq ${fname}_R1_kneaddata_paired_2.fastq
done


#Abundance estimation with braken (phylum, genus, species)
cd k2_reports
mkdir braken
mkdir braken/species
mkdir braken/genus
mkdir braken/phylum

for i in *_report.txt
do
  filename=$(basename "$i")
  fname="${filename%_report.txt}"
  bracken -d /data/MMAC-Shared-Drive/ref_databases/kraken/db_refseq_20200725 -i $i -r 90 -t 10 -l S -o ${fname}_report_species.txt
done
rm *_species.txt
mv *_bracken.txt braken/species/.

for i in *_report.txt
do
  filename=$(basename "$i")
  fname="${filename%_report.txt}"
  bracken -d /data/MMAC-Shared-Drive/ref_databases/kraken/db_refseq_20200725 -i $i -r 90 -t 10 -l G -o ${fname}_report_genus.txt
done
rm *_genus.txt
mv *_bracken.txt braken/genus/.

for i in *_report.txt
do
  filename=$(basename "$i")
  fname="${filename%_report.txt}"
  bracken -d /data/MMAC-Shared-Drive/ref_databases/kraken/db_refseq_20200725 -i $i -r 90 -t 10 -l P -o ${fname}_report_phylum.txt
done
rm *_phylum.txt
mv *_bracken.txt braken/phylum/.


#Generating combined abundance tables in mpa format
mkdir braken/species/mpa
mkdir braken/genus/mpa
mkdir braken/phylum/mpa

for i in braken/species/*_report_bracken.txt
do
  filename=$(basename "$i")
  fname="${filename%_report_bracken.txt}"
  python /data/MMAC-Shared-Drive/ref_databases/kraken/python_scripts/kreport2mpa.py -r $i -o braken/species/mpa/${fname}_mpa.txt --display-header
done

mkdir braken/species/mpa/combined
python /data/MMAC-Shared-Drive/ref_databases/kraken/python_scripts/combine_mpa.py -i braken/species/mpa/*_mpa.txt -o braken/species/mpa/combined/combined_species_mpa.txt
grep -E "(s__)|(#Classification)" braken/species/mpa/combined/combined_species_mpa.txt > braken/species/mpa/combined/bracken_abundance_species_mpa.txt


for i in braken/genus/*_report_bracken.txt
do
  filename=$(basename "$i")
  fname="${filename%_report_bracken.txt}"
  python /data/MMAC-Shared-Drive/ref_databases/kraken/python_scripts/kreport2mpa.py -r $i -o braken/genus/mpa/${fname}_mpa.txt --display-header
done

mkdir braken/genus/mpa/combined
python /data/MMAC-Shared-Drive/ref_databases/kraken/python_scripts/combine_mpa.py -i braken/genus/mpa/*_mpa.txt -o braken/genus/mpa/combined/combined_genus_mpa.txt
grep -E "(g__)|(#Classification)" braken/genus/mpa/combined/combined_genus_mpa.txt > braken/genus/mpa/combined/bracken_abundance_genus_mpa.txt


for i in braken/phylum/*_report_bracken.txt
do
  filename=$(basename "$i")
  fname="${filename%_report_bracken.txt}"
  python /data/MMAC-Shared-Drive/ref_databases/kraken/python_scripts/kreport2mpa.py -r $i -o braken/phylum/mpa/${fname}_mpa.txt --display-header
done

mkdir braken/phylum/mpa/combined
python /data/MMAC-Shared-Drive/ref_databases/kraken/python_scripts/combine_mpa.py -i braken/phylum/mpa/*_mpa.txt -o braken/phylum/mpa/combined/combined_phylum_mpa.txt
grep -E "(p__)|(#Classification)" braken/phylum/mpa/combined/combined_phylum_mpa.txt > braken/phylum/mpa/combined/bracken_abundance_phylum_mpa.txt



#Cleaning up sample names
sed -i -e 's/_report_bracken.txt//g' braken/species/mpa/combined/bracken_abundance_species_mpa.txt
sed -i -e 's/_report_bracken.txt//g' braken/genus/mpa/combined/bracken_abundance_genus_mpa.txt
sed -i -e 's/_report_bracken.txt//g' braken/phylum/mpa/combined/bracken_abundance_phylum_mpa.txt



#Cleaning up top-level folders
cd ..
mkdir bracken_abundance_files
cp k2_reports/braken/species/mpa/combined/bracken_abundance_species_mpa.txt bracken_abundance_files/.
cp k2_reports/braken/genus/mpa/combined/bracken_abundance_genus_mpa.txt bracken_abundance_files/.
cp k2_reports/braken/phylum/mpa/combined/bracken_abundance_phylum_mpa.txt bracken_abundance_files/.

