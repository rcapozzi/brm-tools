#!/usr/bin/env perl

use Data::Dumper;
use BRM;

$Data::Dumper::Indent = 2;

my $tn;
my $hash;
my $out_hash;

$hash = {
  'PIN_FLD_POID' => '0.0.0.1 /account 1 0',
  'PIN_FLD_NAME' => 'Name String',
  'PIN_FLD_AMOUNT' => '9.45',
  'PIN_FLD_START_T' => 70,
  'PIN_FLD_ELEMENT_ID' => 9,
  'PIN_FLD_RESULTS' => {
		'1' => {
		  'PIN_FLD_DESCR' => 'Hello Array 1'
		},
		'2' => {
		  'PIN_FLD_NAME' => 'Hello Name 2'
		},
	},
};

$tn = BRM::Testnap->new;
$out_hash = $tn->xop("PCM_OP_READ_OBJ", 0, $hash);

printf "## %s\n", Dumper($out_hash);

printf "## END\n";
