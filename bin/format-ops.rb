
def format_line(line)
	define, name, number = line.split(/\s+/)
	return "#define %-50.50s %s\n" % [name, number]
end


while line = gets
	if line =~ /^#define/
		line = format_line(line)
	end
	puts line
end
