use Data::Dumper;
use BRM;

$Data::Dumper::Indent = 2;

my $idx = 0;
my $sdk_hash = {
	'PIN_FLD_FIELD' => {
		'1' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_NAME',
			'PIN_FLD_FIELD_TYPE' => 5,
			'PIN_FLD_FIELD_NUM'  => 1,
		},
	},
};

printf "## t_hash2doc enter\n";

my $tn = BRM::Testnap->new;


$hash = {
  'PIN_FLD_POID' => '0.0.0.1 /dummy 1 0',
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

printf "%s\n", $tn->hash2doc($hash);

for (my $i=0;$i<10;$i++){
	printf "%d %s\n", $i, $tn->loopback;
}
printf "STATS: %s\n", $tn->stats;

printf "## END\n";

