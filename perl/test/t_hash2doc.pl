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
		'2' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_END_T',
			'PIN_FLD_FIELD_TYPE' => 8,
			'PIN_FLD_FIELD_NUM'  => 1,
		},
		'3' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_POID',
			'PIN_FLD_FIELD_TYPE' => 7,
			'PIN_FLD_FIELD_NUM'  => 1,
		},
		'4' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_START_T',
			'PIN_FLD_FIELD_TYPE' => 8,
			'PIN_FLD_FIELD_NUM'  => 1,
		},
		'5' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_AMOUNT',
			'PIN_FLD_FIELD_TYPE' => 14,
		},
		'6' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_INDEX',
			'PIN_FLD_FIELD_TYPE' => 1,
		},
		'9' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_RESULTS',
			'PIN_FLD_FIELD_TYPE' => 9,
		},
		'10' => {
			'PIN_FLD_FIELD_NAME' => 'PIN_FLD_DESCR',
			'PIN_FLD_FIELD_TYPE' => 5,
			'PIN_FLD_FIELD_NUM'  => 1,
		},
	}
};

my $tn = BRM::Testnap->new;
my $href = $tn->convert_sdk_fields($sdk_hash->{'PIN_FLD_FIELD'});
$tn->set_dd_fields($href);


$hash = {
  'PIN_FLD_POID' => '0.0.0.1 /dummy 1 0',
  'PIN_FLD_NAME' => 'Name String',
  'PIN_FLD_AMOUNT' => '9.45',
  'PIN_FLD_START_T' => 70,
  'PIN_FLD_INDEX' => 9,
  'PIN_FLD_RESULTS' => {
		'1' => {
		  'PIN_FLD_DESCR' => 'Hello Array 1'
		},
		'2' => {
		  'PIN_FLD_NAME' => 'Hello Name 2'
		},
	},
};

printf $tn->hash2doc($hash);

printf "## END\n";

