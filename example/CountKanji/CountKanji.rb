#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'tmpdir'

tmpdir = Dir.mktmpdir
table = {}

Dir.entries("text").each do |name|
  next if [".", ".."].include?(name)
  path = File.join(tmpdir,name)
  `nkf -w #{File.join("text",name)} > #{path}`
  text = File.read(path)
  
  text.split("").each do |c|
    table[c] =  table.has_key?(c) ? table[c].succ : 1
  end
end

table.keys.sort {|a,b| table[b] <=> table[a] }.each do |key|
  puts "#{key.inspect[1..-2]}:#{table[key]}"
end
