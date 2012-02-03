#!/usr/bin/env perl

$pattern = shift;
@ary = ();

while (<>)
{
	if (/^[\s\t\0]*[DEW] /)
	{
		printf join('',@ary) if (grep(/$pattern/,@ary));
		@ary = ();
	}
	push(@ary, $_);	
}

join('',@ary) if (grep(/$pattern/,@ary));
