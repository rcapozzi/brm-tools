#!/usr/bin/env perl

# Shell
# TAP::*
# Test::*
# Test::Tutorial

package BRM::Testnap;

require Exporter;
use Carp;

BEGIN {
    @ISA = qw(Exporter);
    #@EXPORT = qw(BRM);
}

# module vars and their defaults
$Indent = 2 unless defined $Indent;

# This is more about flist than testnap.
%XXStr2Type = (
		"INT" => 1,
		"ENUM" => 3,
		"STR" => 5,
		"POID" => 7,
		"TSTAMP" => 8,
		"ARRAY" => 9,
		"STRUCT" => 10,
		"DECIMAL" => 14,
		"TIME" => 15,
		);

%Type2Str = (
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

$Fields_ref;

sub convert_sdk_fields {
	my ($c, $sdk_hash) = @_;
	my %hash = ();
	
	# The key is the rec_id. Useless junk.
	# v is a hash with name, num, type.
	while (my($k,$v) = each (%$sdk_hash)) {
		$href{$v->{PIN_FLD_FIELD_NAME}} = [
			$v->{PIN_FLD_FIELD_NUM},
			$v->{PIN_FLD_FIELD_TYPE},
			$Type2Str{$v->{PIN_FLD_FIELD_TYPE}}
		];
	}
	return \%href;
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
	return bless($s, $c);
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

		next if line =~ /^#/;
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

# Convert a hash into a doc. The challenge is that the keys don't 
# contain the data type that the doc needs to include.
#
# A boot strap is needed to first get the DD Objects. Use testnap.
# hash = xop("PCM_OP_SDK_GET_FLD_SPECS",0,"0 PIN_FLD_POID POID [0] 0.0.0.1 /dd/objects 0 0")

sub hash2doc {
	my ($c, $hash, $level, $idx) = @_;
	my @doc = ();
	$level ||= 0;
	$idx ||=0;
	printf "## hash2doc enter level=${level} idx=$idx\n";
	printf "## hash2doc convert %s", ::Dumper($hash);
	#printf "## hash2doc Fields %s", ::Dumper($Fields_ref);
	while (my($fld_name,$fld_value) = each (%$hash)) {
		my $fld_type = $Fields_ref->{$fld_name}->[2]
			|| die "Unknown field \"$fld_name\"";
		printf "## hash2doc loop %-25s %10s [0] %s\n", $fld_name, $fld_type, $fld_value;
		if (ref($fld_value) eq "HASH"){
			while (my($idx,$subhash) = each (%$fld_value)) {
				my @subdoc = $c->hash2doc($subhash,$level+1, $idx);
			}
			# First daddy. Then the kids.
			push @doc, [$level, $fld_name, $fld_type, $idx, $fld_value];
			foreach $elem (@subdoc) {
				push @doc, [ $elem ];
			}
		} else {
			push @doc, [$level, $fld_name, $fld_type, 0, $fld_value];
		}
	}

	printf "## hash2doc exit\n";
	return \@doc;
}

1;
__END__
