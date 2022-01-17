import time
import argparse
import pandas as pd
import dask.dataframe as dd
from dask.diagnostics import ProgressBar
from dask.distributed import Client, LocalCluster


start_time = time.time()
print("--- Initial time is %s min ---" % str(int((time.time() - start_time)/60)))

parser = argparse.ArgumentParser()
parser.add_argument('--file', nargs="+")
parser.add_argument('--field', nargs="+")
parser.add_argument('--memory', nargs='?', type=str, const='3', default='3')
parser.add_argument('--blocksize', nargs='?', type=str, const='64MB', default='64MB')
args = parser.parse_args()

memory_limit = args.memory.upper().replace('GB', '') + 'GB'
blocksize = args.blocksize
blocksize = '25MB'
# set up cluster and workers
# cluster = LocalCluster(processes=False, threads_per_worker=8,
#                       n_workers=1, memory_limit=memory_limit)
# client = Client(cluster)
# client = Client()
# print(client)

file1 = args.file[0]
file2 = args.file[1]

# file1 = 'test_data/initial_extra_anno.tsv'
# file2 = 'test_data/new_extra_anno.tsv'


file1Field = args.field[0]
file2Field = args.field[1]

# file1Field = 'test_data/initial_extra_anno_field.tsv'
# file2Field = 'test_data/new_extra_anno_field.tsv'

# Read extra anno header

df1field = pd.read_csv(file1Field, sep='\t')
df2field = pd.read_csv(file2Field, sep='\t')
df1replaceNAN = ', '.join(['null']*df1field.label.size)
df2replaceNAN = ', '.join(['null']*df2field.label.size)


# Read in the csv files.
col_types = {'release': 'string', 'chromosome': 'string', 'start': int, 'end': int,
             'bin': int, 'reference': 'string', 'alternative': 'string', 'extra_anno': 'string'}
print('Read files')
df1 = dd.read_csv(file1, sep='\t', dtype=col_types, blocksize=blocksize)
print(df1)
df2 = dd.read_csv(file2, sep='\t', dtype=col_types, blocksize=blocksize)
print(df2)

print('Remove brackets ', df2)
df1.anno_data = df1.anno_data.str.strip('[]')
df2.anno_data = df2.anno_data.str.strip('[]')

print('Remove brackets d2 ', df2.anno_data.size.compute())
print('Remove brackets d1 ', df1.anno_data.size.compute())
print("--- Data sets prepared in  %s minutes ---" % str(int((time.time() - start_time)/60)))

# Merge the csv files.

cols = ['release', 'chromosome', 'start', 'end', 'bin', 'reference', 'alternative']
with ProgressBar():
    df = dd.merge(df1, df2, how='outer', on=cols)
    print('Merge files, total size: ', df.anno_data_x.size.compute())
    print("--- Data sets merged after  %s min ---" % str(int((time.time() - start_time)/60)))

df.anno_data_x = df.anno_data_x.fillna(df1replaceNAN)
df.anno_data_y = df.anno_data_y.fillna(df2replaceNAN)
print('Concat extra_anno columns ', df.anno_data_x.size.compute())


# print('Add extra_anno brackets')
df['anno_data'] = '[' + df.anno_data_x + ', ' + df.anno_data_y + ']'
df = df.drop(['anno_data_x', 'anno_data_y'], axis=1)
print('Drop extra anno columns ', df.anno_data.size.compute())
print("--- Merged data set prepared for writing after %s min ---" %
      str(int((time.time() - start_time)/60)))


# Check if it is ok
init_size = dd.concat([df1[cols], df2[cols]]).drop_duplicates().release.size.compute()
final_size = df[cols].drop_duplicates().release.size.compute()

if (init_size != final_size):
    print('Number of lines does not match')

no_fields = df1field.field.size + df2field.field.size - 1
diff_fields = df.anno_data.str.count(',') - no_fields
if (diff_fields.sum().compute() != 0):
    print('Number of fields is wrong')


# Write new extra anno header
print('Output merged file')

dfField = pd.concat([df1field, df2field])
dfField.field = range(1, dfField.field.size+1)

# Write the output.

df.sort_values('chromosome').to_csv('output.tsv', index=False, single_file=True, sep='\t')
dfField.to_csv('outputField.tsv', index=False, sep='\t')

print("--- Merged data set saved after %s min ---" % str(int((time.time() - start_time)/60)))


# client.close()
# cluster.close()
