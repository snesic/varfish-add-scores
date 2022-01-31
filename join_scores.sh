#!/bin/bash

file1=$1
file2=$2

file1Header=$3
file2Header=$4


no_lines1=$(wc -l < $file1Header)
no_lines2=$(wc -l < $file2Header)
echo $no_lines1
echo $no_lines2

# if variant is missing, repeat null for all scores
repeat_null () {
	header=$(printf "%$1s")
	header=${header// /null, }
	header=$(echo $header | sed 's/,*$//g')
	echo $header
}

header1=$(repeat_null $no_lines1)
header2=$(repeat_null $no_lines2)

echo $header1
echo $header2
# Create string out of all columns except extra_anno.
# Sort them
awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7"\t"$8}' $file1 | awk 'NR<2{print $0;next}{print $0| "sort -k1,1"}' > file1.tsv
awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7"\t"$8}' $file2 | awk 'NR<2{print $0;next}{print $0| "sort -k1,1"}' > file2.tsv

# Join files and then remove brackets,
# if a value is missing add null * number_of_scores
# concat extra_anno columns and sort them
join -a 1 -a 2 -j1 -e "null" -t $'\t' -o 0,1.2,2.2 file1.tsv file2.tsv \
	| sed 's/[;]/\t/g' \
	| sed 's/[][]//g' \
	| awk -F'\t' -v a="$header1" \
		'$8=="null" {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"a"\t"$9} $8!="null" {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9}' \
	| awk -F'\t' -v a="$header2" \
		'$9=="null" {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"a} $9!="null" {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9}' \
	| awk -F'\t' 'NR!=1 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t["$8", "$9"]"} NR==1 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8}' \
	| awk 'NR<2{print $0;next}{print $0| "sort -k2.1,2 -k3,3 -n -s"}' > ExtraAnno.tsv

rm file1.tsv
rm file2.tsv


#sort -k 2.1,2 -k3,3 -n -s ExtraAnno1.tsv > ExtraAnno.tsv
# rm ExtraAnno1.tsv
