#!/usr/bin/env perl

use strict;
use IO::Select;
use IPC::Open3;

package BRM::Testnap;

use Carp;

our (@ISA);

BEGIN {
	require Exporter;
    @ISA = qw(Exporter);
    #@EXPORT = qw(BRM);
}

# module vars and their defaults
my $Indent = 2;
my $Debug = 0;
my ($tn0, $tn1, $tn2);

# This is more about flist than testnap.
my %Type2Str = (
			 1 => "INT",
			 3 => "ENUM",
			 5 => "STR",
			 7 => "POID",
			 8 => "TSTAMP",
			 9 => "ARRAY",
			10 => "STRUCT",
			14 => "DECIMAL",
			15 => "TIME",
		);

my $Fields_ref;

sub convert_sdk_fields {
	my ($c, $sdk_hash) = @_;
	my %hash = ();
	
	# The key is the rec_id. Useless junk.
	# v is a hash with name, num, type.
	while (my($k,$v) = each (%$sdk_hash)) {
		$hash{$v->{PIN_FLD_FIELD_NAME}} = [
				$v->{PIN_FLD_FIELD_NUM},
				$v->{PIN_FLD_FIELD_TYPE},
				$Type2Str{$v->{PIN_FLD_FIELD_TYPE}}
			];
	}
	return \%hash;
}

sub set_dd_fields {
	my ($c) = shift;
	my $href = shift;
	$Fields_ref = $href;
}

sub new {
	my($c, $v, $n) = @_;

	my ($s) = {
		level => 0,
		indent => $Indent,
	    last_op_elapsed => 0.0,
		total_op_elapsed => 0.0,
		tn_pid => 0,
		opcode_calls => 0,
	};

	my $bless = bless($s, $c);
	$bless->connect;
	return $bless;
}


# joining an array of strings is better than constantly appending to one.
sub testnap_read {
	my($c) = @_;
	my ($elapsed) = 0.0;
	my @doc = ();
	$Debug && printf STDERR "## Reading testnap enter\n";	
	while (my $line = <$tn1>){
		# printf STDERR "## <testnap says>$line";
		next if $line =~ /^(nap|#)/;
		if ($line =~ /^time: ([0-9\.]+)$/){
			$elapsed = $1;
			last;
		}
		chomp $line;
		push @doc, $line;
	}
	$c->{opcode_calls} += 1;
	$c->{last_op_elapsed} = $elapsed;
	$c->{total_op_elapsed} += $elapsed;	
	my $out = join("\n",@doc);
	$Debug && printf  STDERR "## Reading testnap exit. %s lines. %d chars. %s\n", $#doc+1, length($out), $c->stats;
	return $out;
}

sub stats {
	my($c) = @_;
	my %h = \$c;
	sprintf "## calls=%d, elapsed=%d",
		$c->{opcode_calls},
		$c->{total_op_elapsed};
}

sub xop {
	my($c, $opcode, $opflags, $doc) = @_;
	printf $tn0 "r << +++ 1\n";
	printf $tn0 "%s\n", $doc;
	printf $tn0 "+++\n";
	printf $tn0 "xop %s %s 1\n", $opcode, $opflags;
	my $output = $c->testnap_read;
	return $c->doc2hash($output);
}

sub loopback {
	my($c) = @_;
	my %h = \$c;
	my $doc =<<END
r << +++ 1
0 PIN_FLD_POID              POID [0] 0.0.0.1 /dummy -1
+++
xop PCM_OP_TEST_LOOPBACK 0 1
END
;
	printf $tn0 $doc;
	$c->testnap_read();
}
	
sub connect {
	my($c) = @_;

	if ($c->{tn_pid} != 0 ){
		$c->quit();
	}

	use File::Spec;
	use Symbol qw(gensym);
	use IO::File;

	# Is Perl the new COBOL? Stop insulting COBOL.
	($tn0, $tn1, $tn2) = (gensym, gensym, gensym);

	my $pid = ::open3($tn0, $tn1, $tn2, 'testnap');	
	$c->{tn_pid} = $pid;
	$c->{tn0} = $tn0;
	$c->{tn1} = $tn1;
	$c->{tn2} = $tn2;
	$c->{last_op_elapsed} = 0.0;
	$c->{total_op_elapsed} = 0.0;	

	printf $tn0 "p op_timing on\n";
	# Run an xop to flush stdout
	$c->loopback;
	
	my $doc = "0 PIN_FLD_POID           POID [0] 0.0.0.1 /dd/fields 0 0";
	my $sdk_hash = $c->xop("PCM_OP_GET_DD", 0, $doc);
	my $href = $c->convert_sdk_fields($sdk_hash->{'PIN_FLD_FIELD'});
	$c->set_dd_fields($href);
	return;
}


sub quit {
	my($c) = @_;
	printf $tn0, "q\n";
	waitpid($c->{tn_pid}, 0);
	$c->{tn_exit_status} = $? >> 8;
	$c->{tn_pid} = 0;
}

sub doc2hash {
	my($c, $doc) = @_;
	my @ary = split(/\n/,$doc);
	my %main = ();
	my @stack;           # For any level, point to the current hashref.
	push @stack, \%main;

	$Debug && printf STDERR "## doc2hash enter\n";;
	my ($level, $fld_name, $fld_type, $fld_idx, $fld_value);
	my $lineno = 0;
	foreach my $line (@ary) {
		$lineno++;
		next if $line =~ /^#/;
		if ($line =~ /^(\d+)\s+(.*?)\s+(\w+)\s+\[(\d+)\]\s*(.*$)/) {
			($level, $fld_name, $fld_type, $fld_idx, $fld_value) = (int($1), $2, $3, $4, $5);
		} else {
			croak "Bad initial line parse. Line ${lineno} \"$line\"\n";
		}

		if ($fld_type =~ /STR|POID/) {
			$fld_value =~ s/\"(.*?)\"/$1/;
			$stack[$level]->{$fld_name} = $fld_value;
		} elsif ($fld_type =~ /DECIMAL|INT|ENUM/) {
			$stack[$level]->{$fld_name} = $fld_value + 0;
		} elsif ($fld_type eq "TSTAMP") {
			if ($fld_value =~ /\((\d+?)\)/){
				$fld_value = int($1);
			} else {
				croak "Bad parse value. Line ${lineno} \"$fld_value\"";
			}
			$stack[$level]->{$fld_name} = $fld_value;
		} elsif ($fld_type =~ /ARRAY|SUBSTRUCT/) {
			$stack[$level]->{$fld_name}->{$fld_idx} = {};
			$stack[$level+1] = $stack[$level]->{$fld_name}->{$fld_idx};
		} else {
			croak "Bad parse. Line ${lineno} \"$line\"";
		}
		# printf "## Parsed: %s %-30s %6s [%s] %s\n", $level, $fld_name, $fld_type, $fld_idx, $fld_value;
	}
	$Debug && printf STDERR "## doc2hash exit\n";
	return \%main;
}

# Convert a hash into a doc. The doc is passed to testnap.
# The challenge is that the keys don't 
# contain the data type that the doc needs to include.
#
# A boot strap is needed to first get the DD Objects. Use testnap.
# hash = xop("PCM_OP_SDK_GET_FLD_SPECS",0,"0 PIN_FLD_POID POID [0] 0.0.0.1 /dd/objects 0 0")
sub hash2doc {
	my ($c, $hash, $level, $idx) = @_;
	my @ary = ();
	$level ||= 0;
	$idx ||=0;
	#printf "## hash2doc enter level=${level} idx=$idx\n";
	while (my($fld_name,$fld_value) = each (%$hash)) {
		my $fld_type = $Fields_ref->{$fld_name}->[2]
			|| die "Unknown field \"$fld_name\"";
		# printf "## hash2doc loop %-25s %10s [0] %s\n", $fld_name, $fld_type, $fld_value;

		# Should we branch on the DD field type or the Perl type?
		if (ref($fld_value) eq "HASH"){
			while (my($idx,$subhash) = each (%$fld_value)) {
				push @ary, [$level, $fld_name, $fld_type, $idx, ""];
				my @subdoc = $c->hash2doc($subhash, $level+1, $idx);
				foreach my $elem (@subdoc){
					push(@ary, @$elem);
				}
			}

		} else {
			push @ary, [$level, $fld_name, $fld_type, 0, $fld_value];
		}
	}
	
	# Convert each element of the array to a string.
	if ($level == 0){
		my @doc = ();
		foreach (@ary){
			# A fine example of how Perl sucks.
			my $line = sprintf "%s %-30s %10s [%s] %s", 
				$_->[0], $_->[1], $_->[2], $_->[3], $_->[4];
			push @doc, $line;
		}
		return join("\n", @doc);
	}
	#printf "## hash2doc exit\n";
	return \@ary;
}

1;
__END__
