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

$Type2Str = {
			 1 => "INT",
			 3 => "ENUM",
			 5 => "STR",
			 7 => "POID",
			 8 => "TSTAMP",
			 9 => "ARRAY",
			10 => "STRUCT",
			14 => "DECIMAL",
			15 => "TIME",
		};

$Fields = {};

sub convert_sdk_fields {
	my ($c, $sdk_hash) = @_;
	my $href  = {};
	
	# The key is the rec_id. Useless junk.
	# v is a hash with name, num, type.
	while (my($k,$v) = each (%$sdk_hash)) {
		$href->{$v->{PIN_FLD_FIELD_NAME}} = [
			$v->{PIN_FLD_FIELD_NUM},
			$v->{PIN_FLD_FIELD_TYPE},
			$Type2Str->{$v->{PIN_FLD_FIELD_TYPE}}
		];
	}
	return $href;
}

sub set_dd_fields {
	my ($c) = shift;
	$Fields = shift;
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
	my $main = {};
	my $href;
	my @stack;
	push @stack, $main;
	my ($prev_level);
	
	# printf "## doc2hash enter\n";;
	my ($level, $fld_name, $fld_type, $fld_idx, $fld_value);
	foreach my $line (@ary) {

		if ($line =~ /^(\d+)\s+(.*?)\s+(\w+)\s+\[(\d+)\]\s*(.*$)/) {
			($level, $fld_name, $fld_type, $fld_idx, $fld_value) = (int($1), $2, $3, $4, $5);
		} else {
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
		} elsif ($fld_type =~ /ARRAY|STRUCT/) {
			$stack[$level]->{$fld_name}->{$fld_idx} = {};
			$stack[$level+1] = $stack[$level]->{$fld_name}->{$fld_idx};
		} else {
			croak "Bad parse of \"$line\"";
		}
		$prev_level = $level;
		# printf "## Parsed: %s %-30s %6s [%s] %s\n", $level, $fld_name, $fld_type, $fld_idx, $fld_value;
		
	}
	# printf "## doc2hash exit\n";
	return $main;
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
	printf "## hash2doc ${level} enter\n";
	# printf "## Fields %s\n##\n", ::Dumper($Fields);
	printf "## Convert %s\n", ::Dumper($hash);
	while (my($fld_name,$fld_value) = each (%$hash)) {
		my $fld_type = $Fields->{$fld_name}[2];
		printf "## hash2doc %-25s %10s [X] %s\n", $fld_name, $fld_type, $fld_value;
		if (ref($fld_value) eq "HASH"){
			while (my($idx,$subhash) = each (%$fld_value)) {
				my @subdoc = $c->hash2doc($subhash,$level+1, $idx);
			}
			foreach $elem (@subdoc) {
				push @doc, [ $elem ];
			}
		} else {
			push @doc, [$level, $fld_name, $fld_type, $fld_value];
		}
	}

	printf "## hash2doc exit\n";
	return @doc;
}

1;
__END__
