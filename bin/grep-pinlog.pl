#!/usr/bin/env perl

# Collect each multi-line log message into an array.
# Run the pattern on that array.
# Print the entire message if you match.

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
