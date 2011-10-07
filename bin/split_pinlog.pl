#!/usr/bin/env perl

my $fh;
my $pid;
my %href;

while(<>){
	if (/^[DEW].*?cm:(\d+)/){
		$pid = $1;
		if (! exists($href{$pid})){
			my $file = "cm_$pid.pinlog";
			open($fh, ">", $file) || die "Bad open for $file";
			$href{$pid} = $fh;
		}
		$fh = $href{$pid};
	}
	print $fh $_ if $fh;
}

close($v) while (my($k,$v) = each(%href));

