#!/usr/bin/perl

# This Perl script reads all the csv files in the subdirectory `csv`, assumes
# the first column to be a unique identifier and combines all columns and rows
# into a single csv file.

use warnings;
use strict;
use utf8;
use Text::CSV::Encoded;
use File::Find;
use Data::Dumper;

# Unique key field.
my $KEY = 'TP';

# Hash for tracking $KEY at every test center.
my %TCKEY;

# Global hash of hashes for all data. Key is unique identifier (taken from the
# $KEY column).
my %DATA;

# Global array of all column headings encountered in csv files.
my @COLS;

# Process all csv files
find( \&read_csv, 'csv' );

# return unique elements
sub uniq {
    my %seen;
    grep { !$seen{$_}++ } @_;
}

sub read_csv {
    return unless m/\.csv$/;    # only process files with .csv suffix
    return if m/VTS/; # skip VTS for now

    print "processing $_\n";

    # Get the first number from the file name. This number is used to identify
    # Test Centers. If a $KEY esists at more than one test center, something
    # is terribly wrong.
    my ($tcnum) = (m/^(\d+)/);

    # create Text::CSV object for parsing
    my $csv = Text::CSV->new( { sep_char => ',' } );

    # open CSV file exported from Excel
    open my $fh, "<:encoding(utf8)", $_;

    # read column headers
    my $colsref = $csv->getline($fh);
    push @$colsref, "F1", "F2", "F3", "F4", "F5";

    foreach my $i ( 0 .. $#$colsref ) {
        die "column $i has no header" unless ( $colsref->[$i] );
    }

    # add column headers to global list of headers
    @COLS = uniq( @COLS, @$colsref );

    # set column names (for getline_hr)
    $csv->column_names(@$colsref);

    while ( my $row = $csv->getline_hr($fh) ) {
        # make sure key is uppercase
        $row->{$KEY} = uc $row->{$KEY};

        if ($row->{$KEY} eq 'TP999') {
            print "  skipping TP999\n";
            next;
        }

        # Verify $KEY
        if (!$TCKEY{$row->{$KEY}}) {
            $TCKEY{$row->{$KEY}} = $tcnum;
        }
        elsif ($TCKEY{$row->{$KEY}} ne $tcnum) {
            print "  $row->{$KEY} exists at both TC $tcnum and $TCKEY{$row->{$KEY}}; skipping\n";
            next;
        }

        if ($DATA{$row->{$KEY}}) {
            $DATA{$row->{$KEY}} = ($DATA{$row->{$KEY}}, $row);
        }
        else {
            $DATA{$row->{$KEY}} = $row;
        }
        last;
    }
    $fh->close;

}

# open new output file (make it utf8)
open my $out, ">:encoding(utf8)", "DATA.csv";

# make new Text::CSV object
my $csv = Text::CSV->new( { sep_char => ',' } );

# write column headers to output csv file
$csv->print( $out, \@COLS );
print $out "\n";

# write all data
foreach my $key (sort keys %DATA) {
    my @row = map { $DATA{$key}->{$_}} @COLS;
    $csv->print( $out, \@row );
    print $out "\n";
}

$out->close;

# # dump rest of CSV file to output, but run it through Text::CSV parser to
# # ensure homogenous syntax - and do some data mangling on the fly
# while ( my $row = $csv->getline($fh) ) {
#     foreach my $i ( 0 .. $#$row ) {
#         if ( $row->[$i] eq 'SANT' ) {
#             $row->[$i] = 'TRUE';
#         }
#         elsif ( $row->[$i] eq 'FALSKT' ) {
#             $row->[$i] = 'FALSE';
#         }
#         elsif ( $row->[$i] eq '#SAKNAS!' ) {
#             $row->[$i] = 'NA';
#         }
#     }
#     $csv->print( $out, $row );
#     print $out "\n";
# }

# close $out;
# close $fh;
