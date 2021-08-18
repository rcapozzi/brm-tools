#!/usr/bin/ruby
#
def slurp(io=$stdin)

	ary.each do |line|
		rowid = 0
		if line =~ /^(\d+)\s+(\w.*?)\s+(\w.*)\s\[(.*?)\]\s+(.*?)$/
			level = $1
			fld_name = $2
			fld_type = $3
			index = $4
			fld_value = $5
		end
		if fld_type =~ /ARRAY|SUBSTRUCT/
			fld_value = ""
		end
	end

end

def to_ary(str)
		ary = /^(\d+)\s+(\w.*?)\s+(\w.*)\s\[(.*?)\]\s+(.*?)$/.match(str).to_a
		if ary.size > 0
			ary.shift
			if ary[2] =~ /ARRAY|SUBSTRUCT/
				ary[4] = ""
			end
		else
			ary = [str]
		end
		ary
end

def to_buf(doc)
	out = []
	doc.each do |line|
		out << to_ary(line)
	end
	out
end

def to_txt(ary, indent=2)
	#max_fld = ary.reject{|x| x.size < 2}.inject(0) { |memo,a| memo >= a[1].length ? memo : a[1].length }
	#max_lvl = ary.reject{|x| x.size < 2}.inject(0) { |memo,a| memo >= a[0].to_i ? memo : a[0].to_i}
	#min_lvl = ary.reject{|x| x.size < 2}.inject(99){ |memo,a| memo <= a[0].to_i ? memo : a[0].to_i}
	#max_indent = indent * max_lvl
	#max_fld_length = max_fld + (max_lvl * indent)
	max_fld_length = 36
	format = "%s %-#{max_fld_length}s %9s [%s] %s"
	ary.each do |flds|
		if flds.size > 2
			pads = " " * (indent * flds[0].to_i) + flds[1]
			line = format % [flds[0].to_i, pads, flds[2], flds[3], flds[4] ]
			puts line.strip
		else
			puts flds
		end
	end
	nil
end

if $0 == __FILE__
	# Read stdin
	if ARGV.size == 0
		ary = []
		while line = $stdin.gets
			ary << line
		end
		#ary = $stdin.readlines
		puts "#" * 60
		puts "#"
		puts "#" * 60
		buf = to_buf(ary)
		to_txt(buf)
		exit
	end

	ARGV.each do |file|
		ary = File.readlines(file)
		buf = to_buf(ary)
		to_txt(buf)
	end

end

