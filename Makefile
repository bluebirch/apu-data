.PHONY: csv

csv:
	find raw -name *.xlsx -print0 | xargs -0 -n1 python xlsx-to-csv.py