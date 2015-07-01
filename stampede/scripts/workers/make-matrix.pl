#!/usr/bin/env perl

$| = 1;

use common::sense;
use autodie;
use Data::Dump 'dump';
use File::Basename qw(dirname basename);
use File::Find::Rule;
use Getopt::Long;
use List::MoreUtils qw(uniq);
use Pod::Usage;
use Readonly;

main();

# --------------------------------------------------
sub main {
    my $dir  = '';
    my $skip = '';
    my ($help, $man_page);
    GetOptions(
        'd|dir=s'  => \$dir,
        's|skip:s' => \$skip,
        'help'     => \$help,
        'man'      => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }; 

    unless ($dir) {
        pod2usage('No directory');
    }

    unless (-d $dir) {
        pod2usage("Bad directory ($dir)");
    }

    say STDERR "Looking for files in '$dir'";
    my %skip  = map  { $_, 1 } split(/\s*,\s*/, $skip);
    my @files = grep { 
        (! defined $skip{ basename($_) }) 
        && 
        (! defined $skip{ basename(dirname($_)) })
    } File::Find::Rule->file()->in($dir);

    unless (@files) {
        pod2usage("Found no regular files in dir '$dir'");
    }

    printf STDERR "Processing %s files.\n", scalar @files;

    process(\@files);
}

# --------------------------------------------------
sub process {
    my $files   = shift;
    my $n_files = scalar @$files or return;
    my $i       = 0;
    my %matrix;
    for my $file (@$files) {
        $i++;
        if ($i % 100 == 0) {
            printf STDERR "%-70s\r", sprintf("%3d%%", int($i/$n_files) * 100);
        }

        my $sample1 = basename(dirname($file));
        my $sample2 = basename($file);

        open my $fh, '<', $file;
        local $/;
        my $n = <$fh>;
        close $fh;

        if ($n > 0) {
            $matrix{ $sample1 }{ $sample2 } = sprintf('%.2f', log($n));
        }
    }
    print "\n";

    my @keys     = keys %matrix;
    my @all_keys = sort(uniq(@keys, map { keys %{ $matrix{ $_ } } } @keys));

    say join "\t", '', @all_keys;
    for my $sample1 (@all_keys) {
        say join "\t", 
            $sample1, 
            map { $matrix{ $sample1 }{ $_ } || 0 } @all_keys,
        ;
    }
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

make-matrix.pl - reduce pair-wise mode values to a tab-delimited matrix

=head1 SYNOPSIS

  make-matrix.pl -d /path/to/modes > matrix

Required Arguments:

  -d|--dir   Directory containing the modes

Options:
  -s|--skip  Comma-separated list of sample to skip
  --help     Show brief help and exit
  --man      Show full documentation

=head1 DESCRIPTION

After calculating the pair-wise read modes, run this script to reduce 
them to a matrix for feeding to R.

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2015 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
