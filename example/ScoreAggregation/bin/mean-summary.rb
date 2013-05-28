#!/usr/bin/env ruby

require "pione"

means = Pione.eval("$I[1]").split(":").map{|filename| File.read(filename).chomp.to_f}

10.times do |i|
  count = means.select{|mean| i*10 <= mean and mean < (i+1)*10}.size
  puts '"%s-%s" %s' % [i*10, (i+1)*10-1, count]
end
