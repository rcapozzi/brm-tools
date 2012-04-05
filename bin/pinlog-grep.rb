#!/usr/bin/env ruby
require 'optparse'
module Pinlog

	class Grep

		def self.is_match?(message,pattern)
			# ary.index(/pattern/)
			pattern.match(message)
		end

		def self.process(io,options)
			pattern = options[:pattern]
			invert = options[:v] || false
			new_message = /^[\s\t\0]*[DEW] /
			
			# foo = self.class.new
			regexp = pattern[0] == 47 ? Regexp.new(pattern) : Regexp.new(/#{pattern}/)
			ary = []
			while line = io.gets
				if new_message.match(line)
					message = ary.join
					match = is_match?(message,regexp)
					if (match and not invert)
						puts message
					elsif (invert and not match)
						puts message
					end
					ary = []
				end
				ary << line
			end

			if ary.size > 0
				message = ary.join
				match = is_match?(message,regexp)
				if (match and not invert)
					puts message
				elsif (invert and not match)
					puts message
				end
			end

		end

	end

end

if __FILE__ == $0

	options = {}
	optparse = OptionParser.new do |opts|
		opts.on('-v', "Invert match like -v on grep. Select non-matching messages.") do |v|
			options[:v] = v
		end
	end
	
	optparse.parse!
	options[:pattern] = ARGV.shift
	
	ARGV.each do |file|
		File.open(file){|io| Pinlog::Grep.process(io,options) }
	end
	
end