#!/usr/bin/python

"""
This is a simple xlsx to csv conversion script derived from
https://stackoverflow.com/questions/9884353/xls-to-csv-converter. The file
`Leverans.zip` is expected to be extracted in a subdirectory called `raw`. The
output file name is derived from the input file name and put in the `csv`
subdirectory. The second line of each xlsx file is skipped, since it only
contains descriptions of the headlines (i hope that is true for all xlsx
files).

The following unix command line (which can be found in the Makefile) converts
all xlsx files in one go:

    find raw -name *.xlsx -print0 | xargs -0 -n1 python xlsx-to-csv.py
"""

import sys
import os
import re
import xlrd
import unicodecsv as csv

# get file name from command line
try:
    filename = sys.argv[1]
except IndexError:
    print "no xlsx file specified"
    raise SystemExit

try:
    # open excel workbook
    print "reading", filename
    wb = xlrd.open_workbook(filename)
    sh = wb.sheet_by_index(0)

    # open csv output file
    csv_filename = os.path.splitext(filename)[0]
    csv_filename = re.sub( r"^\w+/", "", csv_filename )
    csv_filename = re.sub( r"[ /]", "_", csv_filename )
    csv_filename = 'csv/' + csv_filename + '.csv'
    print "writing", csv_filename
    csv_file = open(csv_filename, 'w')
    wr = csv.writer(csv_file)

    # write csv data
    wr.writerow(sh.row_values(0))
    for rownum in range(2, sh.nrows):
        wr.writerow(sh.row_values(rownum))

    # close csv file
    csv_file.close()
    print "done"

except IOError:
    print "IO error"
    raise SystemExit
