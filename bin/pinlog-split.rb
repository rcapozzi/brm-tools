#!/usr/bin/env ruby

#E Sun Apr  1 12:25:54 2001  hostname.com  cm:30411  cm_child.c(107):2559 
new_message = /^[\s\t\0]*[DEW] /
regexp = /^\0?([DEW])\s+(.*?)\s+(.*?)\s+(\d+)\s+(.*?)\s+(\d+)\s+(.*?).*?:(.*?)\s/
fh = $stdout
pid = nil
files = Hash.new{|hash, key|
	fname = "xxx_%05d.pinlog" % key.to_i
	$stderr.puts "## Create file #{fname}"
	hash[key] = File.new(fname, "w") 
}

while line = gets
	if line =~ regexp
		fh = files[$8]		
	end
	fh.puts line
end

files.each {|key, fh| fh.close}
