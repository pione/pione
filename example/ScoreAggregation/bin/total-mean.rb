#!/usr/bin/env ruby

means = ARGV[0]

totals = means.split(":").map{|filename| File.read(filename).chomp.to_f}
print totals.reduce(:+) / totals.size
