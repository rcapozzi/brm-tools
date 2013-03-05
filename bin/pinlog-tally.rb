#!/usr/bin/env ruby

require 'date'
require 'optparse'
require 'io/console'

module Pinlog
class Tally
	
	# Produce a count of error messages based on time buckets.
	# io: Any object, such as +IO+ or +File+, that responds to +gets+
	# args: A +Hash+ of options.
	def self.process(io,args={})
		buckets = Hash.new(0)
		interval = args[:i]
		tag = args[:tag]
		
		while line = io.gets
			# Parse E Sun Apr  1 12:25:54 2001  hostname.com  cm:30411  cm_child.c(107):2559 1:<machine>:<program>:0:0:0:0:0
			if line =~ /(\w)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\d\d):(\d\d):(\d\d)\s+(\d+)\s+(.*?)\s+(.*?)\s+/
				(mon, year, day, hour, min, host) = $3, $8, $4, $5, $6, $9
				(host,junk) = host.split(".",2)
				mon = DateTime::ABBR_MONTHNAMES.find_index(mon)
				t = Time.local(year, mon, day.to_i, hour.to_i, min.to_i)
				t = t - (t.to_i % interval) + interval
				key = "%s:%s" % [t.strftime("%Y-%m-%d-%H-%M"), host]
				buckets[key] += 1
			end
		end

		# puts "#seconds,tally,timestamp"
		if args[:hist]
			print_hist(buckets) 
		else
			buckets.keys.sort.each do |key|
				(str,host) = key.split(/:/)
				t = Time.local(*str.split("-"))
				str = t.strftime("%Y-%m-%d,%H:%M")
				str = "%s,%s,%s,%s" % [t.to_i, buckets[key], str, host]
				str << ",#{tag}" if tag
				puts str
			end
		end
	end

	# Print a histogram of the hash.
	# The first 18 columns are labels
	# 20xx-01-29 06:00|      9|----+---x
	# 20xx-01-29 07:00|     13|----+----+--x
	# 20xx-01-29 08:00|     14|----+----+---x
	def self.print_hist(hash)
		rows, cols = $stdout.winsize
		min, max = hash.values.minmax
		range = max - min + 1
		per_col = max / (cols - 25.0)
		per_col = per_col < 1 ? 1 : per_col

		#binding.pry
		#puts "# Per Col: #{per_col}"
		hash.each do |k,v|
			label = k[0,16]
			marks = "-" * (v / per_col)
			puts "%s|%7d|%s" %[label, v, marks]
		end
	end
end	
end

if __FILE__ == $0
	options = {}
	optparse = OptionParser.new do |opts|
		opts.on('-h', '--help', 'Display this screen') do
			puts opts
			exit
		end

		options[:i] = 60 * 60
		opts.on('-i:', "Interval in minutes. Default 60 minutes.") do |i|
			options[:i] = i.to_i * 60
		end

		opts.on('-t:', "Tag to append to each line of output.") do |t|
			options[:tag] = t
		end

		opts.on('--hist', "Print a histogram") do |x|
			options[:hist] = true
		end  
	end
	
	optparse.parse!

	if ARGV.size > 0
		ARGV.each do |file|
			Pinlog::Tally.process(File.open(file), options)
		end
	else
		Pinlog::Tally.process($stdin, options)
	end
end
