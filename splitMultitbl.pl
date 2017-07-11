#!/usr/bin/perl
##script that splits a multi-contig .tbl into .tbl files for each contig
##v0.1 by Robert R Butler III

use warnings;

while(<>){
	BEGIN{ $/=">Feature"; }
	if(/^\s*(\S+)/){ 
		open OUT,">$1.tbl";
		chomp;
		print OUT ">Feature", $_
 	}
}
system "rm Feature.tbl";
