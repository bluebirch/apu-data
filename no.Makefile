ATS=$(wildcard csv/*ATS*)

DATA.csv: $(ATS)
	perl -w bin/combine-csv.pl

.PHONY: csv

csv:
	find data -name *.xlsx -print0 | xargs -0 -n1 python bin/xlsx-to-csv.py