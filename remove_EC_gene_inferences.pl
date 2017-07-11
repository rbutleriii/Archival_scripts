#!/usr/bin/perl
##Script that strips extraneous information from the .tbl file
##For use with Prokka, removes fields that cause issues with GenBank submission
##v0.1 by Robert R Butler III

use strict;
use warnings;

my $usage = 'USAGE = remove_EC_gene_inferences.pl *.tbl';

while (my $file = shift@ARGV){
	open IN, "<$file";
	$file =~ s/.tbl$//;
	open OUT, ">$file.clean.tbl";
	while (my $line = <IN>){
		chomp $line;
		if ($line =~ /^\t{3}Parent/){next;}
		if ($line =~ /^\t{3}EC_number/){next;}
		if ($line =~ /^\t{3}gene\t/){next;}
		if ($line =~ /^\t{3}inference\ssimilar/){next;}
		if ($line =~ /^\t{3}inference\sprotein/){next;}
		if ($line =~ /^\t{3}score/){next;}
		else {print OUT "$line\n";}
	}
}
