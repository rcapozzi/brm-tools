
use Data::Dumper;
use BRM;

$Data::Dumper::Indent = 1;

$doc =<< "END";
0 PIN_FLD_POID              POID [0] 0.0.0.1 /dummy 1 0
0 PIN_FLD_NAME               STR [0] "Name String"
0 PIN_FLD_INDEX              INT [0] 9
0 PIN_FLD_START_T         TSTAMP [0] (70) Blah Blah
0 PIN_FLD_AMOUNT         DECIMAL [0] 9.45
0 PIN_FLD_EVENT        SUBSTRUCT [0]
1   PIN_FLD_RESOURCE_ID      INT [0] 2000002
0 PIN_FLD_RESULTS          ARRAY [1]
1   PIN_FLD_FOO              STR [0] "Hello Array 1"
0 PIN_FLD_RESULTS          ARRAY [2]
1   PIN_FLD_FOO              STR [0] "Good Bye Array 2"
0 PIN_FLD_RESULTS          ARRAY [3]
1   PIN_FLD_FOO              STR [0] "Mult Level 1.3"
1   PIN_FLD_BALANCES       ARRAY [0]
2   PIN_FLD_CURRENT_BAL  DECIMAL [0] 4.75
2   PIN_FLD_END_T         TSTAMP [0] (1230) Blah Blah
END


chomp($doc);
print "$doc\n##\n";

my $tn = BRM::Testnap->new;

my $href;
$href = $tn->doc2hash($doc);
printf "## Results\n%s\n## END\n", Dumper($href);


my $results = {
	"Test level 0 POID" => 
		$href->{PIN_FLD_POID} eq "0.0.0.1 /dummy 1 0" ? "PASS" : "FAIL",

	"Test level 0 STR" => 
		$href->{PIN_FLD_NAME} eq "Name String" ? "PASS" : "FAIL",

	"Test level 0 INT" => 
		$href->{PIN_FLD_INDEX} == 9 ? "PASS" : "FAIL", 

	"Test level 0 DECIMAL" => 
		$href->{PIN_FLD_AMOUNT} == 9.45 ? "PASS" : "FAIL", 

	"Test level 0 TSTAMP" => 
		$href->{PIN_FLD_START_T} == 70 ? "PASS" : "FAIL",

	"Test level 0 SUBSTRUCT" => 
		ref($href->{PIN_FLD_EVENT}) eq "HASH" ? "PASS" : "FAIL",

	"Test level 0 ARRAY" => 
		ref($href->{PIN_FLD_RESULTS}) eq "HASH" ? "PASS" : "FAIL",

	"Test level 1 STR" => 
		$href->{PIN_FLD_RESULTS}{1}{'PIN_FLD_FOO'} eq "Hello Array 1" ? "PASS" : "FAIL",
	};

while ((my ($k, $v) = each(%$results))){
	printf "%-50s: %s\n", $k, $v;
}

exit 0;
