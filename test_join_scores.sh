#!/bin/bash

file1=$1
file2=$2
file3=$3

echo "Number of unique lines in input:"
cat <(awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7}' $file1) \
	<(awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7}' $file2) |\
	awk '!seen[$0]++' | wc -l

echo "Number of unique lines in output:"
awk -F'\t' '{print $1";"$2";"$3";"$4";"$5";"$6";"$7}' $file3 |\
	awk '!seen[$0]++' | wc -l
