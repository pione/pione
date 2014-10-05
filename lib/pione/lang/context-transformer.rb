module Pione
  module Lang
    # ConditionalBranchTransformer is a transformer for all branches.
    module ContextTransformer
      include Util::ParsletTransformerModule

      # Transform +conditional_branch_context+ into Lang::ConditionalBranchContext.
      rule(:conditional_branch_context => sequence(:elements)) {
        Lang::ConditionalBranchContext.new(elements)
      }

      # Transform +param_context+ into Lang::PrameContext.
      rule(:param_context => sequence(:elements)) {
        Lang::ParamContext.new(elements)
      }

      # Transform +flow_rule_condition_context+ into Lang::FlowRuleConditionContext.
      rule(:flow_rule_condition_context => sequence(:elements)) {
        Lang::FlowRuleConditionContext.new(elements)
      }

      # Transform +action_rule_condition_context+ into Lang::ActionRuleConditionContext.
      rule(:action_rule_condition_context => sequence(:elements)) {
        Lang::ActionRuleConditionContext.new(elements)
      }

      # Transform +empty_rule_condition_context+ into Lang::EmptyRuleConditionContext.
      rule(:empty_rule_condition_context => sequence(:elements)) {
        Lang::EmptyRuleConditionContext.new(elements)
      }

      # Transform +flow_context+ into Lang::FlowContext.
      rule(:flow_context => sequence(:elements)) {
        Lang::FlowContext.new(elements)
      }

      # Transform +package_context+ into Lang::PackageContext.
      rule(:package_context => sequence(:elements)) {
        Lang::PackageContext.new(elements)
      }

      # Transform +literal_context+ into Lang::LiteralContext.
      rule(:action_context => simple(:string)) {
        Lang::ActionContext.new(Util::Indentation.cut(String.new(string))).tap do |context|
          line, col = string.line_and_column
          context.set_source_position(package_name, filename, line, col)
        end
      }
    end
  end
end
