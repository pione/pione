#!/usr/bin/env ruby

require "pione"

# info
means = Pione.val "$I[1]"

# calc & output
totals = means.split(":").map{|filename| File.read(filename).chomp.to_f}
print totals.reduce(:+) / totals.size
