
def format_line(line)
	define, name, number = line.split(/\s+/, 3)
	return "#define %-50.50s %s" % [name, number]
end


while line = gets
	if line =~ /^#define/
		line = format_line(line)
	end
	puts line
end
