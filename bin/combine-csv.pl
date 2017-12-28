#!/usr/bin/perl

# This Perl script reads all the csv files in the subdirectory `csv`, assumes
# the first column to be a unique identifier and combines all columns and rows
# into a single csv file.

use warnings;
use strict;
use utf8;
use Text::CSV::Encoded;
use File::Find;
use DateTime::Format::Excel;
use Log::Log4perl qw(:easy);
use Data::Dumper;

# Initialize logging
Log::Log4perl->easy_init(
    {   level  => $DEBUG,
        layout => '%d %-5p %m{indent}%n'
    }
);

# Unique key field.
my $KEY = 'tp';

# Hash for tracking $KEY at every test center.
my %TCKEY;

# Global hash of hashes for all data. Key is unique identifier (taken from the
# $KEY column).
my %DATA;

# Maping column headers
my %MAP = (
    ats => { 'testday' => 'date' },
    hts => { 'neodate' => 'date' },
    vts => {
        'testpersonskod'      => 'tp',
        'angivet testcentrum' => 'tc',
        'dator'               => 'pc',
        'födelsedatum'        => 'birthdate',
        'testtid i minuter'   => 'duration',
        'kön'                 => 'sex',
        'utbildningsnivå'     => 'edlevel'
    }
);

# Which cols to use
my %COLS = (
    ats => [
        qw(date tc birthyr sex edlevel matlang testl reftext
            dnlr dnlf dnlx dnlt
            dblr dblf dblx dblt
            dformlr dformlf dformlx dformlt
            dnar dnaf dnax
            dmipr dmipf dmipx
            dore1r dore1f dore1x dor1r dor1f dor1x dor2r dor2f dor2x dor3r dor3f dor3x dor4r dor4f dor4x dor5r dor5f dor5x
            ds2dr ds2df ds2dx ds3dr ds3df ds3dx
            dpsif1m dpsif1f
            dpbok1m dpbok1f
            dpfig1m dpfig1f
            dblfrr
            dskps1m dskps1f dskps2m dskps2f dskpb1m dskpb1f dskpb2m dskpb2f dskpf1m dskpf1f dskpf2m dskpf2f dsklogar dsklogbr dskadrar dskadrbr dsktidar dsktidbr
            tx01
            dminnar dminnaf dminnax)
    ],
    hts => [
        qw(date tc alter berufskl geschl fragest neoform neostatus neodate neodur neoage
            neo01p neo01n1 neo02p neo02n1 neo03p neo03n1 neo04p neo04n1 neo05p neo05n1 neo06p neo06n1 neo07p neo07n1 neo08p neo08n1 neo09p neo09n1 neo0ap neo0an1 neo0bp neo0bn1 neo0cp neo0cn1 neo0dp neo0dn1 neo0ep neo0en1 neo0fp neo0fn1 neo0gp neo0gn1 neo0hp neo0hn1 neo0ip neo0in1 neo0jp neo0jn1 neo0kp neo0kn1 neo0lp neo0ln1 neo0mp neo0mn1 neo0np neo0nn1 neo0op neo0on1 neo0pp neo0pn1 neo0qp neo0qn1 neo0rp neo0rn1 neo0sp neo0sn1 neo0tp neo0tn1 neo0up neo0un1 neo0vp neo0vn1 neo0wp neo0wn1 neo0xp neo0xn1 neo0yp neo0yn1 neo0zp neo0zn1 neo10p neo10n1 neo11p neo11n1)
    ],
    vts => [
        qw(birthdate duration sex edlevel
            2hand.s1.bt 2hand.s1.gf 2hand.s1.inv 2hand.s1.ke 2hand.s1.mda1 2hand.s1.mda2 2hand.s1.mda3 2hand.s1.mdg 2hand.s1.mfda1 2hand.s1.mfda2 2hand.s1.mfdg 2hand.s1.pfd 2hand.s1.pfda1 2hand.s1.pfda2 2hand.s1.pfda3 2hand.s1.sfd
            aist.s3.a aist.s3.c aist.s3.d aist.s3.e aist.s3.i aist.s3.r aist.s3.s
            als.s1.a als.s1.f als.s1.fp als.s1.g als.s1.k als.s2.a als.s2.f als.s2.fp als.s2.g als.s2.k
            cog.s1.bt cog.s1.krit cog.s1.mtf cog.s1.mtfa cog.s1.mtfj cog.s1.mtfn cog.s1.mtr cog.s1.mtra cog.s1.mtrj cog.s1.mtrn cog.s1.prf cog.s1.srjfn cog.s1.srnfj cog.s1.sumf cog.s1.sumfj cog.s1.sumfn cog.s1.sumges cog.s1.summa cog.s1.summf cog.s1.summr cog.s1.sumr cog.s1.sumrj cog.s1.sumrn
            cog.s4.bt cog.s4.krit cog.s4.mtf cog.s4.mtfa cog.s4.mtfj cog.s4.mtfn cog.s4.mtr cog.s4.mtra cog.s4.mtrj cog.s4.mtrn cog.s4.prf cog.s4.srjfn cog.s4.srnfj cog.s4.sumf cog.s4.sumfj cog.s4.sumfn cog.s4.sumges cog.s4.summa cog.s4.summf cog.s4.summr cog.s4.sumr cog.s4.sumrj cog.s4.sumrn
            fvw.s2.a fvw.s2.bh fvw.s2.bt fvw.s2.mrtfj fvw.s2.mrtfn fvw.s2.mrtrj fvw.s2.mrtrn fvw.s2.prfj fvw.s2.prfja fvw.s2.prfjk fvw.s2.prfjn fvw.s2.prfjsa fvw.s2.prfjsv fvw.s2.prfjv fvw.s2.prrj fvw.s2.prrja fvw.s2.prrjk fvw.s2.prrjn fvw.s2.prrjsa fvw.s2.prrjsv fvw.s2.prrjv fvw.s2.srtfj fvw.s2.srtfn fvw.s2.srtrj fvw.s2.srtrn fvw.s2.sumfj fvw.s2.sumfja fvw.s2.sumfjk fvw.s2.sumfjn fvw.s2.sumfjsa fvw.s2.sumfjsv fvw.s2.sumfjv fvw.s2.sumfn fvw.s2.sumrj fvw.s2.sumrja fvw.s2.sumrjk fvw.s2.sumrjn fvw.s2.sumrjsa fvw.s2.sumrjsv fvw.s2.sumrjv fvw.s2.sumrn
            nvlt.s1.bt nvlt.s1.dd nvlt.s1.dh01 nvlt.s1.dh02 nvlt.s1.dh03 nvlt.s1.dh04 nvlt.s1.dh05 nvlt.s1.dh06 nvlt.s1.dh07 nvlt.s1.dn01 nvlt.s1.dn02 nvlt.s1.dn03 nvlt.s1.dn04 nvlt.s1.dn05 nvlt.s1.dn06 nvlt.s1.dn07 nvlt.s1.dsumh nvlt.s1.dsumn nvlt.s1.fjh01 nvlt.s1.fjh02 nvlt.s1.fjh03 nvlt.s1.fjh04 nvlt.s1.fjh05 nvlt.s1.fjh06 nvlt.s1.fjh07 nvlt.s1.fjn01 nvlt.s1.fjn02 nvlt.s1.fjn03 nvlt.s1.fjn04 nvlt.s1.fjn05 nvlt.s1.fjn06 nvlt.s1.fjn07 nvlt.s1.kdd nvlt.s1.kdsh nvlt.s1.kdsn nvlt.s1.kli nvlt.s1.ksd nvlt.s1.ksfj nvlt.s1.ksrj nvlt.s1.li nvlt.s1.mdfj nvlt.s1.mdfjh nvlt.s1.mdfjn nvlt.s1.mdfn nvlt.s1.mdrj nvlt.s1.mdrjh nvlt.s1.mdrjn nvlt.s1.mdrn nvlt.s1.rjh01 nvlt.s1.rjh02 nvlt.s1.rjh03 nvlt.s1.rjh04 nvlt.s1.rjh05 nvlt.s1.rjh06 nvlt.s1.rjh07 nvlt.s1.rjn01 nvlt.s1.rjn02 nvlt.s1.rjn03 nvlt.s1.rjn04 nvlt.s1.rjn05 nvlt.s1.rjn06 nvlt.s1.rjn07 nvlt.s1.rtrjh01 nvlt.s1.rtrjh02 nvlt.s1.rtrjh03 nvlt.s1.rtrjh04 nvlt.s1.rtrjh05 nvlt.s1.rtrjh06 nvlt.s1.rtrjh07 nvlt.s1.rtrjn01 nvlt.s1.rtrjn02 nvlt.s1.rtrjn03 nvlt.s1.rtrjn04 nvlt.s1.rtrjn05 nvlt.s1.rtrjn06 nvlt.s1.rtrjn07 nvlt.s1.sumd nvlt.s1.sumf nvlt.s1.sumfj nvlt.s1.sumfjh nvlt.s1.sumfjn nvlt.s1.sumfn nvlt.s1.sumr nvlt.s1.sumrj nvlt.s1.sumrjh nvlt.s1.sumrjn nvlt.s1.sumrn nvlt.s1.titel1
            rt.s3.adelay rt.s3.bt rt.s3.difmmz rt.s3.difmrz rt.s3.fr rt.s3.lmmz rt.s3.lmmzmw rt.s3.lmmzow rt.s3.lmrz rt.s3.lmrzmw rt.s3.lmrzow rt.s3.mmz rt.s3.mmzmw rt.s3.mmzow rt.s3.mrz rt.s3.mrzmw rt.s3.mrzow rt.s3.nr rt.s3.nrmw rt.s3.nrow rt.s3.odifmmz rt.s3.odifmrz rt.s3.ommz rt.s3.ommzmw rt.s3.ommzow rt.s3.omrz rt.s3.omrzmw rt.s3.omrzow rt.s3.osdmz rt.s3.osdmzmw rt.s3.osdmzow rt.s3.osdrz rt.s3.osdrzmw rt.s3.osdrzow rt.s3.rmmz rt.s3.rmmzmw rt.s3.rmmzow rt.s3.rmrz rt.s3.rmrzmw rt.s3.rmrzow rt.s3.rr rt.s3.rrmw rt.s3.rrow rt.s3.sdmz rt.s3.sdmzmw rt.s3.sdmzow rt.s3.sdrz rt.s3.sdrzmw rt.s3.sdrzow rt.s3.ur rt.s3.urmw rt.s3.urow
            spm.s1.a spm.s1.b spm.s1.bt spm.s1.c spm.s1.d spm.s1.e spm.s1.ea spm.s1.eb spm.s1.ec spm.s1.ed spm.s1.ee spm.s1.gs spm.s7.a spm.s7.b spm.s7.bt spm.s7.c spm.s7.d spm.s7.e spm.s7.ea spm.s7.eb spm.s7.ec spm.s7.ed spm.s7.ee spm.s7.gs
            vigil.s1.ar vigil.s1.art vigil.s1.br vigil.s1.brt vigil.s1.mwa vigil.s1.mwf vigil.s1.mwr vigil.s1.mwrt vigil.s1.sr vigil.s1.srt vigil.s1.suma vigil.s1.sumf vigil.s1.sumr vigil.s2.ar vigil.s2.art vigil.s2.br vigil.s2.brt vigil.s2.mwa vigil.s2.mwf vigil.s2.mwr vigil.s2.mwrt vigil.s2.sr vigil.s2.srt vigil.s2.suma vigil.s2.sumf vigil.s2.sumr
            spm.s4.a spm.s4.b spm.s4.bt spm.s4.c spm.s4.d spm.s4.e spm.s4.ea spm.s4.eb spm.s4.ec spm.s4.ed spm.s4.ee spm.s4.gs)
    ]
);

my %EDLEVEL;

# Global array of all column headings encountered in csv files.
my @COLS = $KEY;
foreach my $type ( sort keys %COLS ) {
    push @COLS, map {"$type.$_"} @{ $COLS{$type} };
}

# DateTime::Format::Excel obejct for date conversions
my $excel = new DateTime::Format::Excel;

# Process all csv files
find( \&read_csv, 'csv' );

# return unique elements
sub uniq {
    my %seen;
    grep { !$seen{$_}++ } @_;
}

sub read_csv {
    return unless m/\.csv$/;    # only process files with .csv suffix

    # determine file type
    my $filetype = 'unknown';
    if (m/ATS/) {
        $filetype = 'ats';
    }
    elsif (m/HTS/) {
        $filetype = 'hts';
    }
    elsif (m/VTS/) {
        $filetype = 'vts';
    }

    INFO "Processing $_ ($filetype)";

    if ( $filetype eq 'unknown' ) {
        WARN "Unknown file type; skipping.";
        return;
    }

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

    #push @$colsref, "F1", "F2", "F3", "F4", "F5";    # why add more columns?

    # Check column headers and, if necessary, rename them
    foreach my $i ( 0 .. $#$colsref ) {

        # Verify that column header is set (not necessary, i think)
        unless ( $colsref->[$i] ) {
            ERROR "column $i has no header";
            exit 2;
        }

        # Make column header lowercase (that fits better with R)
        $colsref->[$i] = lc $colsref->[$i];

        # Automatic rename of VTS column headers
        if ( $filetype eq 'vts' && $colsref->[$i] =~ m/^(\w+)\/(\w+) \w+ - (\w+)/ ) {
            $colsref->[$i] = join( '.', $1, $2, $3 );
        }

        # And automatic rename of HTS headers
        elsif ( $filetype eq 'hts' ) {
            $colsref->[$i] =~ s/^aneo/neo/;
        }

        # Rename headers according to %MAP hash
        if ( $MAP{$filetype}{ $colsref->[$i] } ) {
            $colsref->[$i] = $MAP{$filetype}{ $colsref->[$i] };
        }

    }

    # set column names (for getline_hr)
    $csv->column_names(@$colsref);

    my $i = 0;

    while ( my $row = $csv->getline_hr($fh) ) {

        # no key?
        if ( !$row->{$KEY} ) {
            ERROR "No key $KEY";
            return;
        }

        # make sure key is uppercase
        $row->{$KEY} = uc $row->{$KEY};

        if ( $row->{$KEY} eq 'TP999' ) {
            DEBUG "Skipping TP999";
            next;
        }

        # Verify $KEY
        if ( !$TCKEY{ $row->{$KEY} } ) {
            $TCKEY{ $row->{$KEY} } = $tcnum;
        }
        elsif ( $TCKEY{ $row->{$KEY} } ne $tcnum ) {
            WARN "$row->{$KEY} exists at both TC $tcnum and $TCKEY{$row->{$KEY}}";
        }

        # Add test center number to key (should make it unique)
        $row->{$KEY} = sprintf( "%s/%d", $row->{$KEY}, $tcnum );

        # Make some data conversions. First date conversions.
        foreach my $datefield (qw(date birthdate)) {
            if ( $row->{$datefield} ) {
                $row->{$datefield} = $excel->parse_datetime( $row->{$datefield} )->ymd();
            }
        }

        # Then educational level.
        if ( $row->{edlevel} ) {
            if ( $row->{edlevel} =~ m/^(\d)/ ) {
                $row->{edlevel} = 'EU' . $1;
            }
            elsif ( $row->{edlevel} =~ m/^\?/ ) {
                $row->{edlevel} = 'Okänd';
            }
            $EDLEVEL{ $row->{edlevel} } = $EDLEVEL{ $row->{edlevel} } ? $EDLEVEL{ $row->{edlevel} } + 1 : 1;
        }

        # Sex/gender
        if ( defined $row->{sex} ) {
            if ( $row->{sex} ) {
                $row->{sex} = ucfirst $row->{sex};
            }
            else {
                $row->{sex} = "NA";
                die;
            }
        }

        # Add row to global hash
        $DATA{ $row->{$KEY} }{$KEY} = $row->{$KEY} unless ( $DATA{ $row->{$KEY} }{$KEY} );
        foreach my $col ( @{ $COLS{$filetype} } ) {
            $DATA{ $row->{$KEY} }{ $filetype . '.' . $col } = $row->{$col};
        }

        $i++;
    }
    INFO "Processed $i entries";
    $fh->close;

}

INFO "Writing output file";

# open new output file (make it utf8)
open my $out, ">:encoding(utf8)", "DATA.csv";

# make new Text::CSV object
my $csv = Text::CSV->new( { sep_char => ',' } );

# write column headers to output csv file
$csv->print( $out, \@COLS );
print $out "\n";

# write all data
foreach my $key ( sort keys %DATA ) {
    my @row = map { $DATA{$key}->{$_} } @COLS;

    # replace missing data with NA
    for my $i ( 0 .. $#row ) {
        $row[$i] = 'NA' if ( !defined $row[$i] || $row[$i] eq '' );
    }

    # write to CSV
    $csv->print( $out, \@row );
    print $out "\n";
}

$out->close;
INFO "Done.";
INFO Dumper \%EDLEVEL;
