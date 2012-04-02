#!/usr/bin/env ruby

buckets = Hash.new(0)

while line = gets
        if line =~ / (\d\d):(\d\d):(\d\d) /
                t = Time.local(1, 1, 1, $1.to_i, $2.to_i/10*10)
                key = "%02.0d:%02.0d" % [t.hour, t.min+10]
                buckets[key] += 1
        end
end

buckets.keys.sort.each do |key|
        puts "%s => %s\n" % [key, buckets[key]]
end


