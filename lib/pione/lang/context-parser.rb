module Pione
  module Lang
    # ContextParser is a set of parsers for PIONE contexts.
    module ContextParser
      include Parslet

      #
      # structural context
      #
      rule(:structural_context_element) { declaration | conditional_branch }
      rule(:structural_context) {(structural_context_element | empty_line).repeat}

      # +conditional_branch_context+ matches conditional branch contexts.
      rule(:conditional_branch_context) {structural_context.as(:conditional_branch_context)}

      # +param_context+ matches parameter block contexts.
      rule(:param_context) {structural_context.as(:param_context)}

      # +flow_rule_condition_context+ matches flow rule condition contexts.
      rule(:flow_rule_condition_context) {structural_context.as(:flow_rule_condition_context)}

      # +action_rule_condition_context+ matches action rule condition contexts.
      rule(:action_rule_condition_context) {structural_context.as(:action_rule_condition_context)}

      # +empty_rule_condition_context+ matches empty rule condition contexts.
      rule(:empty_rule_condition_context) {structural_context.as(:empty_rule_condition_context)}

      # +flow_context+ matches flow contexts.
      rule(:flow_context) {structural_context.as(:flow_context)}

      # +package_context+ matches package contexts.
      rule(:package_context) {structural_context.as(:package_context)}

      #
      # literal context
      #

      # +literal_context+ matches any character sequences.
      rule(:literal_context) { (keyword_End.absent? >> any).repeat }

      # +action_conte+ matches action contexts.
      rule(:action_context) { literal_context.as(:action_context) }
    end
  end
end
