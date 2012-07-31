require 'parslet'
require 'pione/common'

module Pione
  class Document < PioneObject
    # Add ruby shebang line.
    def ruby(str, charset=nil)
      res = "#!/usr/bin/env ruby\n"
      res << "# -*- coding: #{charset} -*-\n" if charset
      return res + str
    end

    # Load a document and return rule table.
    def self.load(filepath)
      parse(File.read(filepath))
    end

    def self.parse(src)
      # parse the document and build the model
      parser = Parser.new
      transformer = Transformer.new
      toplevels = transformer.apply(parser.parse(src))

      # rules and assignments
      rules = toplevels.select{|elt| elt.kind_of?(Rule)}
      assignments = toplevels.select{|elt| elt.kind_of?(Assignment)}

      # make document parameters
      params = assignments.inject(VariableTable.empty) do |vtable, a|
        vtable.tap{|t| t.set(a.variable, a.expr)}
      end.to_params

      # set document parameters into rules
      rules.each do |rule|
        rule.params.merge!(params)
      end

      # make rule table
      table = rules.inject({}) do |tbl, rule|
        tbl.tap{|x| x[rule.rule_path] = rule}
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

    # Returns main rule of main package.
    def main
      @rules["&main:Main"]
    end

    def root_rule(params)
      Rule::RootRule.new(main, params)
    end
  end
end

require 'pione/parser'
require 'pione/transformer'
