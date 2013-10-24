#!/usr/bin/env ruby

require "pione"
require "erb"

title    = Pione.val "$*"
content  = Pione::Location[Pione.val("$I[1]")].read
template = Pione.val "$I[2]"

puts ERB.new(File.read(template)).result(binding)
