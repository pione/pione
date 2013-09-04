module Pione
  module Lang
    # RuleCondition is a storage of rule conditions.
    class RuleCondition < StructX
      member :inputs, default: lambda { Array.new }
      member :outputs, default: lambda { Array.new }
      member :features, default: lambda { Array.new }
      member :param_definition, default: lambda { Hash.new }
      member :constraints, default: lambda { Array.new }
      member :annotations, default: lambda { Array.new }
    end

    # ConstituentRuleSet is a storage of constituent rules in flow rule.
    class ConstituentRuleSet < StructX
      member :rules, default: lambda { RuleExprSequence.new }
    end

    # ActionContext is a storage of shell scripts in action rule.
    class ActionContent < StructX
      member :content, default: lambda { String.new }
    end

    # RuleDefinition is a base class for flow rule definition, action rule
    # definition, and empty rule definition.
    class RuleDefinition < StructX
      immutable true

      # rule condtions
      member :rule_condition_context
      # parameter sets
      member :param_sets, default: Model::ParameterSetSequence.new

      def rule_type
        case self
        when FlowRuleDefinition, RootRuleDefinition
          "flow"
        when ActionRuleDefinition, EmptyRuleDefinition
          "action"
        end
      end
    end

    # FlowRuleDefinition is a definition of flow rule that consists of condition
    # context and flow context.
    class FlowRuleDefinition < RuleDefinition
      # flow context
      member :flow_context
    end

    # Definition of action rules.
    class ActionRuleDefinition < RuleDefinition
      # action context(shellscript)
      member :action_context
    end

    # Definition of empty rules.
    class EmptyRuleDefinition < RuleDefinition
    end

    class RootRuleDefinition < FlowRuleDefinition
    end

    # Definition of parameters.
    class ParameterDefinition < StructX
      # parameter type: basic/advanced
      member :type
      # parameter name (string)
      member :name
      # default value (expression)
      member :value
    end

    # Definition of packages. packages have its id and the parent id.
    class PackageDefinition < StructX
      # package id
      member :package_id
      # parent package id
      member :parent_id
      # definition table of package parameter
      member :param_definition, default: lambda {|_| Hash.new }
      # parameter set
      member :param, default: lambda {|_| ParameterSetSequence.new }
    end
  end
end
