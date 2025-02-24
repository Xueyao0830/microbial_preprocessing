#!/bin/bash

# Function to check SRR type using vdb-dump
check_srr_type() {
    local srr=$1
    result=$(vdb-dump -R 1 -C SPOT_COUNT,READ_COUNT --format tab "$srr" 2>&1)
    if echo "$result" | awk '{ if($2 > 1) print "paired"; else print "single"; }' ; then
        echo "paired"
    else
        echo "single"
    fi
    echo "$result"
}

# Function to download SRR based on type
download_srr() {
    local srr=$1
    local srr_type=$2

    if [ "$srr_type" == "paired" ]; then
        fastq-dump --split-files "$srr"
        echo "Downloaded paired-end SRR: $srr"
    else
        fastq-dump "$srr"
        echo "Downloaded single-end SRR: $srr"
    fi
}

# Main function
main() {
    local srr_list=("$@")
    for srr in "${srr_list[@]}"; do
        echo "Checking type for $srr"
#        srr_type=$(check_srr_type "$srr")
#        echo "$srr is $srr_type"
#        if [ -n "$srr_type" ]; then
#            download_srr "$srr" "$srr_type"
#        else
#            echo "Failed to determine SRR type for $srr. Skipping download."
#        fi
         check_srr_type
    done
}

# Replace the SRR IDs below with your actual list of SRR IDs
srr_list=("ERR688605")

main "${srr_list[@]}"