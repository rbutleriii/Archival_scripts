#!/usr/bin/perl

##v0.1.1 Robert R Butler III on 3/6/2017
##parsing fields from ClinVar and adding to affy chip master file
##Must not have "," in field values, change all to something else first
##Reads each line and defines variable for Header field (replaces " " with "_"; and '"' with '')
##grabs data from ClinVar using Entrez Direct tools (must install)

use strict;
use warnings;
use Timer::Runtime;
use Sort::Naturally;
use Data::Dumper qw(Dumper); #for debug

my $usage = 'USAGE = perl affy_chip_parse.pl *.csv '; #gimme the right inputs

##loading Affy chip hash (%table)
my $file = $ARGV[0] or die $usage; #going through text file and making outfile
system "dos2unix $file";
print "Loading Affy array table...\n";
open(IN,"$file");
$file =~ s/.csv//; #dropping extension for outfile
open(OUT,">$file.out.txt");
my %row; # hash of column values for each line/row
my %table; #hash of row hashes
my @names = (); #column headers
my @values = (); #line/row values
my $affyID; #Probe.Set.ID is unique key for table hash
while (my $line = <IN>){ #reading lines for variant info
	chomp $line;
	if ($line =~ /^VariationID/){
		@names = split(/,/, $line); #column names
		for (@names){s/ /_/g}; #replacing " " with "_"
		for (@names){s/"//g}; #getting rid of "
	} elsif ($line =~ /\S+/){ #splitting variant info columns into variables
		@values = split(/,/, $line);
		for (@names){s/ /_/g}; #replacing " " with "_"
		for (@values){s/"//g}; #getting rid of "
		@row{@names} = @values;
		$affyID = $values[1]; #defining subhash by Probe.Set.ID
		for my $name (keys %row){
			$table{$affyID}{$name} = $row{$name}; #putting values into hash
		}
	} else {next;}
}
close IN;
##end loading Affy chip hash (%table)

##fetch Entrez Direct for submitter data
print "Querying NCBI for Submitter Data...\n";
my @VIDlist;
for my $key (keys %table){#grabbing all VariationIDs in the affy table
	if ($table{$key}{VariationID} eq 'NA'){#skipping NA VID
		next;
	} else {
		push @VIDlist, $table{$key}{VariationID};
	}
}
my @UIDlist = keys { map { $_ => 1 } @VIDlist }; #remove redundant UIDs
open(OUT2,">UIDs.temp"); #write UIDs to file
for my $UIDlist (@UIDlist){
	print OUT2 "$UIDlist\n";
}
close OUT2;
system 'epost -db clinvar -input UIDs.temp | efetch -db clinvar -format variation | xtract -pattern VariationReport -element @VariationID \
-block ObservationList -if ClinicalSignificance/Explanation -element ClinicalSignificance/Explanation -else -lbl "\-" \
-block ObservationList -sep "|" -element @VariationID -element ClinicalSignificance/Description \
-block Germline -tab "|" -element @SubmitterName ClinicalSignificance/Description > efetch.txt';
open(IN2, "efetch.txt");
print "Adding submitter data to table...\n";
#Column Headers added
my @newnames = ("ClinVar_Significance", "Invitae_Sig", "GeneDx_Sig", "Ambry_Sig", "Number_of_Submissions", "Submission_Details"); #new columns
push (@names, @newnames); #adding the column headers to the affy table
while (my $line = <IN2>){
	chomp $line;
	my ($VariationID, $subdetail ,$observationIDs, $observsigs, $subsigs) = split ("\t", $line, 5); # breaking up clinvar results sections
	for ($observsigs, $subsigs){s/, /;/g}; #changing ", " to ";"
	for ($observsigs, $subsigs){s/ /_/g}; #changing " " to "_"
	#ClinVar_Significance value
	my @OIDs = split(/\|/, $observationIDs); #VariationID for each clinical observation
	my @Osigs = split(/\|/, $observsigs); #clinical observations
	my %clinobs; #clinical observations hash by VariationID
	@clinobs{@OIDs} = @Osigs;
	#Invitae/Genedx/Ambry Clinical Significances
	my %clinsubs; #initialize submitter hash
	my @subs = split(/\|/, $subsigs); #already an ordered array "key, value, key, value"
	my $submittercount;
	while (@subs){ #Have to deal with duplicate significances without deleting them 
		my $key = shift@subs;
		my $value = shift@subs;
		my $submittercount;
		if (exists $clinsubs{$key}){ #if exists add a z to the key
			$clinsubs{$key . "z"} = $value; #will make key, keyz, keyzz for output
		} else { #kind of a waste since we don't care about most submitters, but wont't delete or overwrite stuff
			$clinsubs{$key} = $value;
		}
	}
	$submittercount = scalar(keys %clinsubs); # of submissions
	#fill new array values
	for my $key (keys %table){
		if ($table{$key}{VariationID} eq "NA"){ #if in affy array but no varID, make "NA"
			$table{$key}{ClinVar_Significance} = "NA";
			$table{$key}{Invitae_Sig} = "NA";
			$table{$key}{GeneDx_Sig} = "NA";
			$table{$key}{Ambry_Sig} = "NA";
			$table{$key}{Number_of_Submissions} = "NA";
			$table{$key}{Submission_Details} = "NA";
		} elsif ($table{$key}{VariationID} eq "$VariationID"){ #VarID in %table matches ClinVar query
			$table{$key}{ClinVar_Significance} = $clinobs{$VariationID};
			$table{$key}{Number_of_Submissions} = $submittercount;
			$table{$key}{Submission_Details} = $subdetail;
			if (exists $clinsubs{Invitae}){ #either they have submitter data or "NA"
				$table{$key}{Invitae_Sig} = $clinsubs{Invitae};
			} else {
				$table{$key}{Invitae_Sig} = "NA";
			}
			if (exists $clinsubs{GeneDx}){
				$table{$key}{GeneDx_Sig} = $clinsubs{GeneDx};
			} else {
				$table{$key}{GeneDx_Sig} = "NA";
			}if (exists $clinsubs{Ambry_Genetics}){
				$table{$key}{Ambry_Sig} = $clinsubs{Ambry_Genetics};
			} else {
				$table{$key}{Ambry_Sig} = "NA";
			}
		} else {next;} #if variantID not in ClinVar query have to fill in undef values later w/ "NA"
	}
}
close IN2;
##end fetch Entrez Direct for submitter data

##print Affy chip hash to file
print "Writing output file...\n";
print OUT join("\t", @names), "\n";#printing header
shift@names; #remove VariationID from column list see line 132
for my $key (sort { ncmp($table{$a}{VariationID},$table{$b}{VariationID}) || $table{$a}{"Probe.Set.ID"} cmp $table{$b}{"Probe.Set.ID"} } keys %table){
	print OUT "$table{$key}{VariationID}"; #no tab in front of first column
	for my $name (@names){ #above sort by VariationID (naturally) then Probe.Set.ID
		if (exists $table{$key}{$name}){ #filling in blank spaces with "NA*"
			print OUT "\t$table{$key}{$name}"; #print tab separated row for each "Probe.Set.ID" key found in VarIDs
		} else { 
			print OUT "\tNA\*"; #if variantID not in ClinVar query have to fill in undef values later w/ "NA*"
			print "Some VariationIDs were not in the ClinVar query \"NA\*\"\n";
		}
	}
	print OUT "\n"; #line return
}
close OUT;
##end print Affy chip hash to file

#print Dumper \%clinsubs; #for debug
#print Dumper \%clinobs; #for debug

