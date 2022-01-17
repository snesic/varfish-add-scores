# Add new scores to VarFish

VarFish allows import of any variant score so that a user can filter or sort variants by that score. A ready-to-use table of CADD (and other) scores is already provided for download . Here, we describe how to generate and import scores to VarFish.

## Generate score

We use REVEL score as an example. VarFish requires two TSV files where one contains data with the following structure:

|  release | chromosome  |  start | end  | bin  |reference|alternative|anno_data|
|---|---|---|---|---|---|---|---|
GRCh37 | X|100075460|100075460|1348|T|A|0.883|
GRCh37 | X|100515545|100515545|1351|C|G|0.123|

and the other contains information on the values from `anno_data`. Note that the values are comma-separated so that each value correspond to the name from the second file:

|field|label|
|---|---|
1|REVEL|

Dummy example files are given in `test_data` folder. They are also used to test the code.






## Join scores


### Input

In order to include scores that come from different sources one would have to create two joined TSV files following the structure defined above. In our dummy test folder we have two files with scores. The first one, `initial_extra_anno_field.tsv` mitigates scores provided by `bihealth`:

```
# cat test_data/initial_extra_anno.tsv
[...]
GRCh37	1	11	11	1	A	C	[null, null, null, null, null, null, null, 3]
GRCh37	1	550	550	1	A	C	[null, null, null, null, null, null, null, 4]
GRCh37	X	1000754080	1000754080	1349	T	C	[null, null, null, null, 44, null, null, 6
[...]
```
together with the column names of the values

```
# cat test_data/initial_extra_anno_field.tsv
field	label
1	Sngl1000bp
2	Freq10000bp
3	Rare10000bp
4	Sngl10000bp
5	dbscSNV-ada_score
6	dbscSNV-rf_score
7	RawScore
8	CADD-PHRED   
```

The second file is mitigating REVEL score  
```
# cat test_data/new_extra_anno.tsv
[...]
GRCh37	1	11	11	1	A	C	[0.1]
GRCh37	1	550	550	1	A	C	[0.2]
GRCh37	2	11	11	1	A	C	[0.1]
GRCh37	5	11	11	1	A	C	[0.1]
[...]
# cat test_data/new_extra_anno_field.tsv
field	label
1	REVEL
```

### Usage

The main issue here is the size of the files we need to merge. The size of the scores provided by `bihealth` is approx. `50GB` while `REVEL` is around `3GB`. A `bash` solution is:

```
# ./join_scores.tsv test_data/initial_extra_anno.tsv \
                    test_data/new_extra_anno.tsv \
                    test_data/initial_extra_anno_field.tsv \
                    test_data/new_extra_anno_field.tsv
```

A `python` solution based on pandas/dask runs:

```
# python join_scores_dask.py \
            --file test_data/initial_extra_anno.tsv test_data/new_extra_anno.tsv \
            --field test_data/initial_extra_anno_field.tsv test_data/new_extra_anno_field.tsv \
            --memory 1 --blocksize 25MB
```
#### Pros & cons

|  solution | pros| cons |
|---|---|---|
|bash|1. fast <br> 2. infrastructure efficient  | 1. not readable <br>|
|python dask|1. readable <br> 2. easy to maintain | 1. hard to adjust for the infrastrucure <br> 2. slow |


### Results

Once the scores are merged, the output files should look like `test_data/ExtraAnno.tsv`:

```
# cat test_data/ExtraAnno.tsv
[...]
GRCh37  1       11      11      1       A       C       [null, null, null, null, null, null, null, 3, 0.1]
GRCh37  1       550     550     1       A       C       [null, null, null, null, null, null, null, 4, 0.2]
[...]
# cat test_data/ExtraAnnoField.tsv
field	label
1	Sngl1000bp
2	Freq10000bp
3	Rare10000bp
4	Sngl10000bp
5	dbscSNV-ada_score
6	dbscSNV-rf_score
7	RawScore
8	CADD-PHRED
9	REVEL
```

### Tests


1. Check if the number of unique lines excluding `extra_anno` files matches between the new file and the concatinated input files.
2. Check if the number of values in each line corresponds to the number of fields in the output field file (ExtraAnnoField.tsv).
