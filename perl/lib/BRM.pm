#!/usr/bin/env perl

use strict;
use IO::Select;
use IPC::Open2;
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
	};

	my $bless = bless($s, $c);
	
	$bless->connect;
	
	# Boot strap our own data dictionary.
	# $tn->get_sdk_field();
	#my $href = $tn->convert_sdk_fields($sdk_hash->{'PIN_FLD_FIELD'});
	#$tn->set_dd_fields($href);
	
	return $bless;
}

sub connect3 {
	my($c) = @_;
	my %h = \$c;
	if ($h{tn_pid} != 0 ){
		$c->quit();
	}

	my($wtr, $rdr, $err) = (0,0,0);
	my $pid = ::open3($wtr, $rdr, $err, 'testnap');
	printf "## Connected to testnap\n";
	printf $wtr "p logging on\n";
	printf $wtr "p op_timing on\n";

	printf "## Reading testnap\n";
	while (my $line = <$rdr>){
		printf "## Read $line\n";
	}
	$h{tn_pid} = $pid;
	printf "Connected pid: ${pid}\n";	
}

sub connect {
	my($c) = @_;
	my %h = \$c;
	if ($h{tn_pid} != 0 ){
		$c->quit();
	}

	my($rdr, $wtr);
	$rdr = ">&";
	my $tn_pid = ::open2($rdr, \*Writer, "testnap 2>/dev/null");
	printf Writer "p logging on\n";
	printf Writer "p op_timing on\n";
	printf Writer "robj - DB /account 1\n";

	printf "## Reading testnap pipe output\n";
	while (my $line = <Reader>){
		printf "## testnap:<$line>\n";
		last;
	}
	
	$h{tn_pid} = $tn_pid;

	printf "## Return %s\n", $?;
	printf "Connected pid: ${tn_pid}\n";
	
}

sub quit {
	my($c) = @_;
	my %h = \$c;
	printf $h{tn0}, "q\n";
	waitpid($h{tn_pid}, 0);
	$h{
		tn_exit_status => $? >> 8,
		tn_pid => 0,
		tn0 => 0,
		tn1 => 0,
		tn2 => 0,
	};
}

sub doc2hash {
	my($c, $doc) = @_;
	my @ary = split(/\n/,$doc);
	my %main = ();
	my @stack;           # For any level, point to the current hashref.
	push @stack, \%main;

	# printf "## doc2hash enter\n";;
	my ($level, $fld_name, $fld_type, $fld_idx, $fld_value);
	foreach my $line (@ary) {

		next if $line =~ /^#/;
		if ($line =~ /^(\d+)\s+(.*?)\s+(\w+)\s+\[(\d+)\]\s*(.*$)/) {
			($level, $fld_name, $fld_type, $fld_idx, $fld_value) = (int($1), $2, $3, $4, $5);
		} else {
			croak "Bad initial line parse for \"$line\"\n";
			next;
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
				croak "Bad parse value \"$fld_value\"";
			}
			$stack[$level]->{$fld_name} = $fld_value;
		} elsif ($fld_type =~ /ARRAY|SUBSTRUCT/) {
			$stack[$level]->{$fld_name}->{$fld_idx} = {};
			$stack[$level+1] = $stack[$level]->{$fld_name}->{$fld_idx};
		} else {
			croak "Bad parse of \"$line\"";
		}
		# printf "## Parsed: %s %-30s %6s [%s] %s\n", $level, $fld_name, $fld_type, $fld_idx, $fld_value;
	}
	# printf "## doc2hash exit\n";
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
	#printf "## hash2doc convert %s", ::Dumper($hash);
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
