#!/bin/bash

file1=$1
file2=$2

file1Header=$3
file2Header=$4

no_lines1=$(wc -l < $file1Header)

# Create string out of all columns except extra_anno.
# Sort them
awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7"\t"$8}' $file1 | awk 'NR<2{print $0;next}{print $0| "sort -k1,1"}' > file1.tsv
awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7"\t"$8}' $file2 | awk 'NR<2{print $0;next}{print $0| "sort -k1,1"}' > file2.tsv

# Join files and then remove brackets,
# if a value is missing add null * number_of_scores (hard-coded at the moment)
# concat extra_anno columns and sort them
join -a 1 -a 2 -j1 -e "null" -t $'\t' -o 0,1.2,2.2 file1.tsv file2.tsv \
	| sed 's/[;]/\t/g' \
	| sed 's/[][]//g' \
	| awk -F'\t' '$8=="null" {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tnull, null, null, null, null, null, null, null\t"$9} $8!="null" {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9}' \
	| awk -F'\t' 'NR!=1 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t["$8", "$9"]"} NR==1 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8}' \
	| awk 'NR<2{print $0;next}{print $0| "sort -k2.1,2 -k3,3 -n -s"}' > ExtraAnno.tsv

rm file1.tsv
rm file2.tsv


#sort -k 2.1,2 -k3,3 -n -s ExtraAnno1.tsv > ExtraAnno.tsv
# rm ExtraAnno1.tsv
