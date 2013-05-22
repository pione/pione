#!/usr/bin/env ruby

p ARGV
name, score_f, pre_stat_f, mean_f = ARGV

scores = File.readlines(score_f).map{|line| line.split(" ")[1].to_i}
mean = scores.reduce(:+).to_f / scores.size
sd = Math.sqrt(scores.map{|i| (mean-i) ** 2}.reduce(:+) / scores.size)

File.open(pre_stat_f, "w") do |file|
  file.write <<TXT
# Statistics of #{name}

## Scores

![Score of #{name}](#{name}_bar-graph.png)

## Statistics

| stat  | value                    |
|-------|--------------------------|
| Sum   | #{scores.reduce(:+)}     |
| Count | #{scores.size}           |
| Max   | #{scores.max}            |
| Min   | #{scores.min}            |
| Med   | #{scores[scores.size/2]} |
| Mean  | #{mean}                  |
| SD    | #{sd}                    |
TXT
end

File.open(mean_f, "w") {|file| file.write mean}
