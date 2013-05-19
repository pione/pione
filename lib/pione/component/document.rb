module Pione
  module Component
    class Document < PioneObject
      # Add ruby shebang line.
      def ruby(str, charset=nil)
        res = "#!/usr/bin/env ruby\n"
        res << "# -*- coding: #{charset} -*-\n" if charset
        return res + str
      end

      # Load a rule document and return it.
      def self.load(filepath)
        parse(File.read(filepath))
      end

      # Parse a rule document string.
      def self.parse(src)
        # parse the document and build the model
        parser = Parser::DocumentParser.new
        transformer = Transformer::DocumentTransformer.new
        toplevels = transformer.apply(parser.parse(src))

        # rules and assignments
        rules = toplevels.select{|elt| elt.kind_of?(Component::Rule)}
        assignments = toplevels.select{|elt| elt.kind_of?(Assignment)}
        assignments.each {|assignment| assignment.set_toplevel(true)}
        user_params = Naming::ParamLine.values(toplevels)
        Naming::ParamBlock.values(toplevels).each do |elts|
          user_params += elts
        end
        assignments += user_params.map do |param|
          param.tap do |x|
            x.set_toplevel(true)
            x.set_user_param(true)
          end
        end

        # make document parameters
        params = assignments.inject(VariableTable.empty) do |vtable, a|
          vtable.tap{|t| t.set(a.variable, a.expr)}
        end.to_params

        # set document parameters into rules
        rules.each {|rule| rule.params.merge!(params)}

        # make rule table
        table = rules.inject({}) do |tbl, rule|
          tbl.tap{|x| x[rule.rule_path] = rule}
        end
        return new(table, params)
      end

      attr_reader :rules
      attr_reader :params

      # Creates a document.
      def initialize(rules, params)
        @rules = rules
        @params = params
        instance_eval(&b) if block_given?
      end

      # Returns the named rule.
      # @param [String] name
      #   rule path
      # @return [Pione::Model::Rule]
      def [](name)
        @rules[name].params.merge!(@params)
        @rules[name]
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
        Component::RootRule.new(main, @params.merge(params))
      end
    end
  end
end
