#!/usr/bin/env ruby

fh = $stdout
pid = nil
files = Hash.new{|hash, key|
	fname = "xxx_#{key}.pinlog"
	$stderr.puts "## Create file #{fname}"
	hash[key] = File.new(fname, "w") 
}

while line = gets
	if line =~ /^[DEW].*?\w+:(\d+)/
		fh = files[$1]		
	end
	fh.puts line
end

files.each {|key, fh| fh.close}
