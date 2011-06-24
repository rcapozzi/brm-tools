#!/usr/bin/env perl

use Data::Dumper;
use BRM;

$Data::Dumper::Indent = 2;
$BRM::Testnap::Debug = 1;

my $tn;
my $hash;
my $out_hash;

$hash = {
  'PIN_FLD_POID' => '0.0.0.1 /account 1 0',
};

$tn = BRM::Testnap->new;
$out_hash = $tn->xop("PCM_OP_READ_OBJ", 0, $hash);
printf "## %s\n", Dumper($out_hash);

$out_hash = $tn->xop("PCM_OP_TEST_LOOPBACK", 0, $hash);
printf "## %s\n", Dumper($out_hash);

printf "## END\n";
