require 'optparse'
require 'pathname'

OptionParser.new do |opt|
  opt.on("-d DIR") {|dir| $dir = dir}
end.parse!(ARGV)

abort "you should specify output directory" unless $dir

class Person
  attr_reader :name
  attr_reader :value
  attr_reader :range

  def initialize(name, value, range)
    @name = name
    @value = value
    @range = range
  end

  def generate_score
    score = @value + (Random.rand(@range)*@value).to_i
    score > 100 ? 100 : score
  end
end

list = [
  Person.new("A", 70, -0.3..0.3),
  Person.new("B", 60, -0.5..0.5),
  Person.new("C", 65, -0.2..0.2),
  Person.new("D", 85, -0.2..0.2),
  Person.new("E", 50, -0.5..0.5),
  Person.new("F", 60, -0.6..0.6),
  Person.new("G", 40, -0.4..0.4),
  Person.new("H", 70, -0.5..0.5),
  Person.new("I", 55, -0.1..0.1),
  Person.new("J", 65, -0.1..0.1),
  Person.new("K", 60, -0.2..0.2),
  Person.new("L", 75, -0.1..0.1),
  Person.new("M", 80, -0.5..0.5),
  Person.new("N", 45, -0.2..0.2),
  Person.new("O", 65, -0.2..0.2),
  Person.new("P", 70, -0.1..0.1),
  Person.new("Q", 55, -0.1..0.1),
  Person.new("R", 50, -0.1..0.1),
  Person.new("S", 60, -0.2..0.2),
  Person.new("T", 65, -0.3..0.3),
  Person.new("U", 70, -0.2..0.2),
  Person.new("V", 55, -0.3..0.3),
  Person.new("W", 60, -0.2..0.2),
  Person.new("X", 75, -0.2..0.2),
  Person.new("Y", 70, -0.5..0.5),
  Person.new("Z", 65, -0.2..0.2)
]

list.each do |person|
  path = Pathname.new($dir) + ("%s.score" % person.name)
  path.open("w+") do |file|
    15.times do |i|
      file.puts "%d %s" % [i+1, person.generate_score]
    end
  end
end
