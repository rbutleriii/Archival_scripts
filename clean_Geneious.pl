#!/usr/bin/perl
##Script that strips extraneous information from the .tbl file exported from Geneious
##It also generates new locus tags and new protein_ids for resubmission to GenBank
##Also clips the excess characters from feature name beyond Contig_#### or Plasmid_#### won't work if your contigs are not named in that format
##locus_tag XXXX_##### -> XXXX_02#####; new pid gnl|WGS:xxxx|locus_tag
##After running script, remember to replace the "xxxx" in the pid with your WGS accession prefix!
##For subequent submissions, replace  $version with a higher number (e.g. 3, 4, 5)
##v0.1 by Robert R Butler III

use strict;
use warnings;

my $usage = 'USAGE = remove_EC_gene_inferences.pl *.tbl';
my $locuspre = ();
my $locustail = ();
my $version = 2;

while (my $file = shift@ARGV){
	open IN, "<$file";
	$file =~ s/.tbl$//;
	open OUT, ">$file.clean.tbl";
	while (my $line = <IN>){
		chomp $line;
		if ($line =~ /^\t{3}locus_tag\t([A-Z0-9]+)_(\d+)/){
			$locuspre = $1;
			$locustail = $2;
			printf OUT "\t\t\tlocus_tag\t${locuspre}_%02d$locustail\n", $version;
		}
		elsif ($line =~ /^\t{3}protein_id/){
			printf OUT "\t\t\tprotein_id\tgnl|WGS:xxxx|${locuspre}_%02d$locustail\n", $version;
		}
		elsif ($line =~ /^(>Feature [A-Za-z]+_[A-Za-z0-9]{1,4})/){
			print OUT "$1\n";
		}
		elsif ($line =~ /^\t{3}Parent/){next;}
		elsif ($line =~ /^\t{3}EC_number/){next;}
		elsif ($line =~ /^\t{3}gene\t/){next;}
		elsif ($line =~ /^\t{3}inference\ssimilar/){next;}
		elsif ($line =~ /^\t{3}inference\sprotein/){next;}
		elsif ($line =~ /^\t{3}score/){next;}
		elsif ($line =~ /^\t{3}note\tGeneious/){next;}
		elsif ($line =~ /^\d+\t\d+\tmisc_feature/){next;}
		else {print OUT "$line\n";}
	}
}
