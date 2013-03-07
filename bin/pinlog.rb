#!/usr/bin/env ruby
require 'date'
require 'optparse'
require 'io/console'
require 'thor'

module Pinlog

	class Grep

		def self.is_match?(message,pattern)
			# ary.index(/pattern/)
			pattern.match(message)
		end
		
		def self.print_message(ary,regexp,invert)
			message = ary.join
			match = is_match?(message,regexp)
			if (match and not invert)
				puts message
			elsif (invert and not match)
				puts message
			end
		end

		def self.process(io,options)
			pattern = options[:pattern]
			invert = options[:invert] || false
			new_message = /^[\s\t\0]*[DEW] /
			
			# foo = self.class.new
			regexp = pattern[0] == 47 ? Regexp.new(pattern) : Regexp.new(/#{pattern}/)
			ary = []
			while line = io.gets
				if new_message.match(line)
					print_message(ary,regexp,invert)
					ary = []
				end
				ary << line
			end

			if ary.size > 0
				print_message(ary,regexp,invert)
			end

		end

	end

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





class PinlogCli < Thor

	desc "grep", "Grep for a patten in a pinlog message"
	option :invert, aliases: '-v', desc: "Invert the match pattern to select non-matching messages", type: :boolean
	option :pattern, aliases: "-p", desc: "Patten to match", required: true
	def grep(*files)
		if files.size == 0
			Pinlog::Grep.process($stdin,options)
		else
			files.each do |file|
				File.open(file){|io| Pinlog::Grep.process(io,options) }
			end
		end
	end
	

	desc "tally", 'Tally/count pinlog messages'
	option :interval, aliases: "i", desc: "Interval in minutes"
	option :t, desc: "Tag to append to line"
	option :hist, desc: "Print a histogram"
	def tally(*files)
		if files.size == 0
			Pinlog::Tally.process($stdin, options)
		else
			files.each do |file|
				Pinlog::Tally.process(File.open(file), options)
			end
		end
	end

	desc "split", "Split a pinlog based on a pid. Reads stdin."
	def split
		#E Sun Apr  1 12:25:54 2001  hostname.com  cm:30411  cm_child.c(107):2559 
		new_message = /^[\s\t\0]*[DEW] /
		regexp = /^\0?([DEW])\s+(.*?)\s+(.*?)\s+(\d+)\s+(.*?)\s+(\d+)\s+(.*?).*?:(.*?)\s/
		fh = $stdout
		pid = nil
		files = Hash.new do|hash, key|
			fname = "xxx_%05d.pinlog" % key.to_i
			$stderr.puts "## Create file #{fname}"
			hash[key] = File.new(fname, "w") 
		end

		while line = gets
			if line =~ regexp
				fh = files[$8]		
			end
			fh.puts line
		end

		files.each {|key, fh| fh.close}
	end

end


if __FILE__ == $0
	PinlogCli.start(ARGV)
end
