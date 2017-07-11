# Archival_scripts

Previously used scripts not included in published work. Mostly in Perl.

splitMultitbl.pl - script that splits a multi-contig .tbl file into .tbl files for each contig

splitGBK.pl - script that splits a multi-contig .gbk file into .gbk files for each contig

remove_EC_gene_inferences.pl - For use with Prokka output, removes fields that cause issues with GenBank submission

clean_Geneious.pl - Script that strips extraneous information from the .tbl file exported from Geneious

affy_chip_parse.pl - Pulling info fields from ClinVar and adding to Affymetrix chip master file csv, output is tsv


Several scripts utilize outputs of other progams, primarily Prokka (Seeman, 2014) and Geneious (Commercial software: http://www.geneious.com/)

Seemann T. Prokka: rapid prokaryotic genome annotation. Bioinformatics. 2014 Jul 15;30(14):2068-9. PMID:24642063
