#!/usr/bin/perl

# This is a simple script that basically combines the first two lines of a CSV
# file columnwise and fixes the headers so that they are somewhat proper R
# vector names.

use warnings;
use strict;
use utf8;
use Text::CSV::Encoded;
use Data::Dumper;

my $csv = Text::CSV->new( { sep_char => ';' } );

# open CSV file exported from Excel
open my $fh, "<:encoding(iso8859-1)", "WTS+ATS-export.csv";

# open new output file (make it utf8)
open my $out, ">:encoding(utf8)", "WTS+ATS.csv";

# read the first two lines of the CSV file
my @row;
for my $i ( 0 .. 1 ) {
    $row[$i] = $csv->getline($fh);
}

# combine the first two rows columnwise
my $prefix = '';
my @colhead;
for my $i ( 0 .. $#{ $row[0] } ) {
    $prefix = $row[0][$i] . "." if ( $row[0][$i] );
    my $colhead = $prefix . $row[1][$i];

    # cleanup
    $colhead =~ s/-/ /g;         #remove dashes
    $colhead =~ s/\s+/./g;       # convert all whitespace to dots
    $colhead =~ s/[^\w\.]//g;    # remove non-alphanumeric and non-space

    push @colhead, $colhead;
}

# output new headers
$csv->print( $out, \@colhead );
print $out "\n";

# dump rest of CSV file to output, but run it through Text::CSV parser to
# ensure homogenous syntax - and do some data mangling on the fly
while ( my $row = $csv->getline($fh) ) {
    foreach my $i ( 0 .. $#$row ) {
        if ( $row->[$i] eq 'SANT' ) {
            $row->[$i] = 'TRUE';
        }
        elsif ( $row->[$i] eq 'FALSKT' ) {
            $row->[$i] = 'FALSE';
        }
        elsif ( $row->[$i] eq '#SAKNAS!' ) {
            $row->[$i] = 'NA';
        }
    }
    $csv->print( $out, $row );
    print $out "\n";
}

close $out;
close $fh;
