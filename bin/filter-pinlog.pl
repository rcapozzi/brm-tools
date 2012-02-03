#!/usr/bin/env perl

# Collect each multi-line log message into an array.
# Run the pattern on that array.
# Print the entire message if you match.

$pattern = shift;
$i = 0;
@ary = ();

while (<>)
{
	if (/^[\s\t\0]*[DEW] /)
	{
		$i = grep(/$pattern/,@ary);
		printf join('',@ary) if $i == 0;
		@ary = ();
	}
	push(@ary, $_);	
}
$i = grep(/$pattern/,@ary);
printf join('',@ary) if $i == 0;

