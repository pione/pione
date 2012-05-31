require 'parslet'
require 'innocent-white/common'
require 'innocent-white/rule'

module InnocentWhite
  class Document < InnocentWhiteObject
    # Add ruby shebang line.
    def ruby(str, charset=nil)
      res = "#!/usr/bin/env ruby\n"
      res << "# -*- coding: #{charset} -*-\n" if charset
      return res + str
    end

    class Package
      attr_reader :name
      def initialize(name)
        @name = name
      end
    end

    # Load a document and return rule table.
    def self.load(filepath)
      parse(File.read(filepath))
    end

    def self.parse(src)
      parser = Parser.new
      transformer = Transformer.new
      rules = transformer.apply(parser.parse(src))
      table = {}
      rules.each do |rule|
        table[rule.path] = rule
      end
      return new(table)
    end

    attr_reader :rules

    def initialize(rules = {})
      @rules = rules
      instance_eval(&b) if block_given?
    end

    def [](name)
      @rules[name]
    end
  end
end

require 'innocent-white/parser'
require 'innocent-white/transformer'
