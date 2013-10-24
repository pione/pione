#!/usr/bin/env ruby

require "pione"

name_list = Pione.val '$*.join(":")'
scores_f  = Pione.val '$I[1].join(":")'
means_f   = Pione.val '$I[2].join(":")'

total_mean = Pione::Location[Pione.val("$I[3]")].read.to_f

means    = means_f.split(":").map{|file| File.read(file).to_f}
total_sd = Math.sqrt(means.map{|mean| (total_mean-mean) ** 2}.reduce(:+) / means.size)
names    = name_list.split(":").sort

devs = names.inject({}) do |tbl, name|
  mean = Pione::Location["%s.mean" % name].read.to_i
  dev = 50 + 10 * (mean - total_mean) / total_sd
  Pione::Location["%s.dev" % name].write(dev)
  tbl.tap {|x| x[name] = dev}
end

lines = names.map do |name|
  scores = File.readlines("%s.score" % name).map{|line| line.split(" ")[1].to_i}
  mean = Pione::Location["%s.mean" % name].read.to_f
  [name, scores, mean, devs[name]].flatten.join(" | ")
end

report = <<TXT
# Total Statistics

## Histgram

![Histgram of mean scores](histgram.png)

## Scores

| name | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | Mean | Deviation |
|------|---|---|---|---|---|---|---|---|---|----|----|----|----|----|----|------|-----------|
#{lines.map{|line| "| %s |" % line}.join("\n")}
TXT

Pione::Location[Pione.val("$O[2]")].write(report)

