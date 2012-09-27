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
      return new(table, params)
    end

    attr_reader :rules

    # Create a document.
    def initialize(rules, params)
      @rules = rules
      @params = params
      instance_eval(&b) if block_given?
    end

    # Returns the named rule.
    # @param [String] name
    #   rule path
    def [](name)
      @rules[name].params.merge(@params)
    end

    # Returns main rule of main package.
    # @return [Rule]
    #   main rule of main package
    def main
      @rules["&main:Main"].params.merge!(@params)
      @rules["&main:Main"]
    end

    # Returns root rule.
    # @param [Parameters] params
    #   root root parameter
    # @return [RootRule]
    #   root rule
    def root_rule(params)
      Rule::RootRule.new(main, params.merge(@params))
    end
  end
end

require 'pione/parser'
require 'pione/transformer'
