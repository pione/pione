require 'parslet'
require 'pione/common'
require 'pione/rule'

module Pione
  class Document < PioneObject
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

require 'pione/parser'
require 'pione/transformer'
