#!/usr/bin/env ruby

require 'erb'

title, md, template = ARGV
content = File.read(md)

puts ERB.new(File.read(template)).result(binding)
