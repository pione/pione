#!/usr/bin/env ruby

name_list, scores_f, means_f, total_mean_f, total_stat_f = ARGV

total_mean = File.read(total_mean_f).chomp.to_f
means = means_f.split(":").map{|file| File.read(file).chomp.to_f}
total_sd = Math.sqrt(means.map{|mean| (total_mean-mean) ** 2}.reduce(:+) / means.size)
names = name_list.split(":").sort

devs = names.inject({}) do |tbl, name|
  mean = File.read(name + ".mean").chomp.to_i
  dev = 50 + 10 * (mean - total_mean) / total_sd
  File.open(name + ".dev", "w") {|file| file.write dev}
  tbl.tap {|x| x[name] = dev}
end

lines = names.map do |name|
  scores = File.readlines("%s.score" % name).map{|line| line.split(" ")[1].to_i}
  mean = File.read("%s.mean" % name).chomp.to_f
  [name, scores, mean, devs[name]].flatten.join(" | ")
end

File.open(total_stat_f, "w") do |file|
  file.write <<TXT
# Total Statistics

## Histgram

![Histgram of mean scores](histgram.png)

## Scores

| name | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | Mean | Deviation |
|------|---|---|---|---|---|---|---|---|---|----|----|----|----|----|----|------|-----------|
#{lines.map{|line| "| %s |" % line}.join("\n")}
TXT
end

