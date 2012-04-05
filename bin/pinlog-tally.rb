#!/usr/bin/env ruby

require 'date'
require 'optparse'

class Tally
	
	def self.process(io,args={})
		buckets = Hash.new(0)
		pattern = args[:p]
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

if __FILE__ == $0
	options = {}
	optparse = OptionParser.new do |opts|

		options[:i] = 60 * 60
		opts.on('-i:', "Interval in minutes. Default 60 minutes.") do |i|
			options[:i] = i * 60
		end

		opts.on('-t:', "Tag to append to each line of output.") do |t|
			options[:tag] = t
		end

		opts.on('-h', '--help', 'Display this screen') do
			puts opts
			exit
		end
  
	end
	
	optparse.parse!

	if ARGV.size > 0
		ARGV.each do |file|
			Tally.process(File.open(file), options)
		end
	else
		Tally.process($stdin, options)
	end
end
