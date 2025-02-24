#!/bin/bash

# Create directories for reference genomes and indexes
mkdir -p /proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db
CONTAMINATE_DB_PATH="/proj/naiss2024-6-169/users/x_xwang/data/database/contaminate_db"

# Download other genomes (example for cat genome felCat8)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/felCat8/bigZips/felCat8.fa.gz
gunzip $CONTAMINATE_DB_PATH/felCat8.fa.gz

# Repeat for other genomes (canFam3, mm10, rn6, susScr3, galGal4, bosTau8)
# Download dog genome (canFam3)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/canFam3/bigZips/canFam3.fa.gz
gunzip $CONTAMINATE_DB_PATH/canFam3.fa.gz

# Download mouse genome (mm10)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz
gunzip $CONTAMINATE_DB_PATH/mm10.fa.gz

# Download rat genome (rn6)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/rn6/bigZips/rn6.fa.gz
gunzip $CONTAMINATE_DB_PATH/rn6.fa.gz

# Download pig genome (susScr3)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/susScr3/bigZips/susScr3.fa.gz
gunzip $CONTAMINATE_DB_PATH/susScr3.fa.gz

# Download chicken genome (galGal4)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/galGal4/bigZips/galGal4.fa.gz
gunzip $CONTAMINATE_DB_PATH/galGal4.fa.gz

# Download cow genome (bosTau8)
wget -P $CONTAMINATE_DB_PATH ftp://hgdownload.cse.ucsc.edu/goldenPath/bosTau8/bigZips/bosTau8.fa.gz
gunzip $CONTAMINATE_DB_PATH/bosTau8.fa.gz

# Download bacterial plasmids
wget -P $CONTAMINATE_DB_PATH ftp://ftp.ncbi.nlm.nih.gov/refseq/release/plasmid/plasmid.*.genomic.fna.gz
gunzip $CONTAMINATE_DB_PATH/plasmid.*.genomic.fna.gz
cat $CONTAMINATE_DB_PATH/plasmid.*.genomic.fna > $CONTAMINATE_DB_PATH/plasmid.fna

# Download plastomes
wget -P $CONTAMINATE_DB_PATH ftp://ftp.ncbi.nlm.nih.gov/refseq/release/plastid/plastid.*.genomic.fna.gz
gunzip $CONTAMINATE_DB_PATH/plastid.*.genomic.fna.gz
cat $CONTAMINATE_DB_PATH/plastid.*.genomic.fna > $CONTAMINATE_DB_PATH/plastid.fna

# Download UniVec sequences
wget -P $CONTAMINATE_DB_PATH ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec_Core
mv $CONTAMINATE_DB_PATH/UniVec_Core $CONTAMINATE_DB_PATH/univec.fna

# Build Bowtie2 indexes
module load bowtie2/2.3.5.1

bowtie2-build $CONTAMINATE_DB_PATH/felCat8.fa $CONTAMINATE_DB_PATH/felCat8_index
bowtie2-build $CONTAMINATE_DB_PATH/canFam3.fa $CONTAMINATE_DB_PATH/canFam3_index
bowtie2-build $CONTAMINATE_DB_PATH/mm10.fa $CONTAMINATE_DB_PATH/mm10_index
bowtie2-build $CONTAMINATE_DB_PATH/rn6.fa $CONTAMINATE_DB_PATH/rn6_index
bowtie2-build $CONTAMINATE_DB_PATH/susScr3.fa $CONTAMINATE_DB_PATH/susScr3_index
bowtie2-build $CONTAMINATE_DB_PATH/galGal4.fa $CONTAMINATE_DB_PATH/galGal4_index
bowtie2-build $CONTAMINATE_DB_PATH/bosTau8.fa $CONTAMINATE_DB_PATH/bosTau8_index
bowtie2-build $CONTAMINATE_DB_PATH/plasmid.fna $CONTAMINATE_DB_PATH/plasmid_index
bowtie2-build $CONTAMINATE_DB_PATH/plastid.fna $CONTAMINATE_DB_PATH/plastid_index
bowtie2-build $CONTAMINATE_DB_PATH/univec.fna $CONTAMINATE_DB_PATH/univec_index