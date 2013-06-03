module Pione
  module Component
    class DuplicatedRuleError < StandardError
      def initialize(rule_path)
        @rule_path = rule_path
      end

      def message
        "There are duplicated rule %s in docuemtn" % @rule_path
      end
    end

    class Document < StructX
      class << self
        # Load a PIONE rule document.
        #
        # @param location [Location,String]
        #   location of the PIONE document
        # @return [Component::Document]
        #   the document
        def load(src, package_name="Main")
          src = src.read if src.kind_of?(Location::BasicLocation)

          # parse the document and build the model
          parser = Parser::DocumentParser.new
          transformer = Transformer::DocumentTransformer.new(package_name)
          toplevels = transformer.apply(parser.parse(src))

          # rules and assignments
          rules = toplevels.select{|elt| elt.kind_of?(Component::Rule)}
          assignments = Naming[:AssignmentLine, :ParamLine, :ParamBlock].values(toplevels).flatten

          # make document parameters
          params = assignments.inject(VariableTable.empty) do |vtable, a|
            vtable.tap{|t| t.set(a.variable, a.expr)}
          end.to_params

          # set document parameters into rules
          rules.each {|rule| rule.condition.params.merge!(params)}

          return new(package_name, rules, params)
        end
      end

      member :package_name
      member :rules
      member :params

      # Find the named rule.
      #
      # @param name [String]
      #   rule name
      # @return [Component::Rule]
      def find(name)
        rules.find {|rule| rule.name == name}
      end

      # Create a root rule which calls the rule with the parameters.
      #
      # @param rule [Component::Rule]
      #   rule that is called by the root rule
      # @param [Parameters] params
      #   user parameters
      # @return [Component::RootRule]
      #   root rule
      def create_root_rule(rule, user_params)
        Component::RootRule.new(rule, params.merge(user_params))
      end
    end
  end
end
