#!/usr/bin/env ruby

def flags(n)
bits = "%b" % n # create a string representing each bit of this value

# Calculate some formating sizes
size = ("%x"%n).size + 1
hex_mask = "0x%0#{size}X"
template = "%03d %#{bits.size}b  #{hex_mask}  %#{size}d"

puts "Dec %d => Hex #{hex_mask} => Bits %b" % [n,n,n]
puts "=== %b  #{hex_mask}" % [n, n]

i = 0
bits.reverse.each_char do |x|
if x == '1'
power = 2**i
puts template % [i, power, power, power]
end
i += 1
end
puts '###'
nil
end

if __FILE__ == $0
flags(ARGV[0])
end

