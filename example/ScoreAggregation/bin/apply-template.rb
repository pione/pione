#!/usr/bin/env ruby

require "pione"
require "erb"

title    = Pione.eval "$*"
content  = Location[Pione.eval("$I[1]")].read
template = Pione.eval "$I[2]"

puts ERB.new(File.read(template)).result(binding)
