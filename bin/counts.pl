#!/usr/bin/env perl

%h=();
$doc = `ps -lu pin`;
@ary = split(/\n/,$doc);
foreach(@ary){ 
	@a=split; 
	$h{$a[$#a]}+=1;
	$h{all}+=1;
}
printf "cm:%s dmo:%s dmf:%s\n",$h{cm},$h{dm_oracle},$h{dm_fusa};

%h=();
%seen=();
$doc = `/usr/sbin/lsof -c cm -a -u pin -c cm -a -i 4 -P`;
@ary = split(/\n/,$doc);

foreach(@ary){
	@a=split(/\s+/);
	printf STDERR "XXX $_\n";
	if ($a[7] =~/.*->(.*?):/){
		$seen{$a[1]}++;
		$h{$1}++;
	}
}

# Delete the pid for master cms.
foreach(@ary){
	delete $seen{$1} if (/^cm\s+(\d+).*?:\d+ \(LISTEN\)/);
}


@keys = sort(keys(%seen));
foreach $k(@keys){
	$v = $seen{$k};
	next unless $v == 1;
	printf "orphans %-6s => %s\n", $k, $v;
}

@keys = sort(keys(%h));
foreach $k(@keys){
	$v = $h{$k};
	printf "lsof %-16s => %s\n", $k, $v;
}
