#!/usr/bin/env ruby

require 'pione'

# infos
name    = Pione.val "$*"
score_f = Pione.val "$I[1]"

# calc stat
scores = File.readlines(score_f).map{|line| line.split(" ")[1].to_i}
mean   = scores.reduce(:+).to_f / scores.size
sd     = Math.sqrt(scores.map{|i| (mean-i) ** 2}.reduce(:+) / scores.size)

# build report
report = <<TXT
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

# output
Pione::Location[Pione.val("$O[1]")].write(report)
Pione::Location[Pione.val("$O[2]")].write(mean)
