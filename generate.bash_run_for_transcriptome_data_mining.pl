#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/qli/lib/';
use Getopt::Long;
#-----------------------------------------------------------------------------
##----------------------------------- MAIN ------------------------------------
##-----------------------------------------------------------------------------
my $usage = "perl generate.bash_run_for_genomic_par_ext.pl [-options] <scaf_rid file> <id dir> <concatenated reads file> <bx_db> \n
Options:
--select_reads
--deconcatenate_reads
--trinity_assembly
--blastx
--annotation
";
my ($select_reads,$deconcatenate_reads,$trinity_assembly,$blastx,$annotation);
GetOptions('select_reads' => \$select_reads,
	   'deconcatenate_reads'=> \$deconcatenate_reads,
	   'trinity_assembly'=> \$trinity_assembly,
	    'blastx'=> \$blastx,
	    'annotation'=> \$annotation
);
die $usage unless defined $ARGV[3];	 
my $scaf_rid_file = $ARGV[0];
my $id_dir = $ARGV[1];
my $conca_reads = $ARGV[2];
my $bx_db = $ARGV[3];
select_reads($scaf_rid_file, $id_dir, $conca_reads) if $select_reads;
deconcatenate_reads($scaf_rid_file, $id_dir) if $deconcatenate_reads;
trinity_assembly($scaf_rid_file, $id_dir) if $trinity_assembly;
blastx($scaf_rid_file,$id_dir,$bx_db) if $blastx;
annotation($scaf_rid_file,$id_dir) if $annotation;

#-----------------------------------------------------------------------------
##---------------------------------- SUBS -------------------------------------
##-----------------------------------------------------------------------------
sub select_reads{
	my $scaf_rid_file=shift;
	my $id_dir=shift;
	my $conca_reads=shift;
	open(IN, "<$scaf_rid_file");
	my $count = 1;
	while(my $id = <IN>){
    		chomp($id);
    		print "fasta_tool --select $id_dir/$id $conca_reads > $id_dir/$id.fa &\n";
    		print "wait\n" if($count % 20 == 0);
    		$count++;
	}
	close(IN);
}

sub deconcatenate_reads{
	my $scaf_rid_file=shift;
	my $id_dir=shift;
	open(IN, "<$scaf_rid_file");
	my $count = 1;
	while(my $id = <IN>){
    		chomp($id);
    		print "~/anaconda/bin/python deconcatenate_fasta.py -i  $id_dir/$id.fa -o $id_dir/$id &\n";
    		print "wait\n" if($count % 20 == 0);
    		$count++;
	}
	close(IN);
}

sub trinity_assembly{
	my $scaf_rid_file=shift;
	my $id_dir=shift;
	#print "`mkdir $id_dir/trin`\n`cd $id_dir/trin`\n";
	open(IN, "<$scaf_rid_file");
	my $count = 1;
	while(my $id = <IN>){
    		chomp($id);
    		print "Trinity --seqType fa --max_memory 30G --left $id_dir/$id"."_1.fa --right $id_dir/$id"."_2.fa --CPU 6 --bflyHeapSpaceMax 5G --bflyCPU 2 --KMER_SIZE 32 --min_contig_length 75 --min_per_id_same_path 99 --max_diffs_same_path 1 --max_internal_gap_same_path 3 --output $id_dir/trin/$id --full_cleanup &\n";
    		print "wait\n" if($count % 2 == 0);
    		$count++;
	}
	close(IN);
}



sub blastx{
	my $scaf_rid_file=shift;
	my $id_dir=shift;
	my $bx_db=shift;
	open(IN, "<$scaf_rid_file");
	my $count = 1;
	while(my $id= <IN>){
		chomp($id);
		print "blastx -db $bx_db -query $id.Trinity.fasta -num_threads 1 -outfmt '6 std qframe sframe' -evalue 1e-3 -word_size 3 -matrix BLOSUM62 -gapopen 11 -gapextend 1 -comp_based_stats t -seg no -soft_masking true -out $id.bx.out &\n";
		print "wait\n" if($count % 20 == 0);
		$count++;
	}
	close(IN);
}

sub annotation{
	my $scaf_rid_file=shift;
	my $id_dir=shift;
	open(IN, "<$scaf_rid_file");
	my $count =1;
	while(my $id=<IN>){
		chomp($id);
		print "annotate.ncbi.pl $id.bx.out $id.Trinity.fasta > annotated.$id.fa.txt &\n";
    print "wait\n" if($count % 20 == 0);
    $count++;
	}
	close(IN);
}

