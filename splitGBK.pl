#!/usr/bin/perl
##script that splits a multi-contig .gbk into .gbk files for each contig
##v0.1 by Robert R Butler III

use warnings;

while(<>){
	BEGIN{ $/="LOCUS"; }
	if(/^\s*(\S+)/){ 
		open OUT,">$1.gbk";
		chomp;
		print OUT "LOCUS", $_
 	}
}
