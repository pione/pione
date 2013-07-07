module Pione
  module Parser
    # FlowElementParser is a set of parser atoms for flow elements.
    module FlowElementParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include ExprParser

      rule(:flow_elements) { (flow_element | empty_line).repeat(1) }
      rule(:flow_elements!) { flow_elements.or_error("flow elements not found") }

      # +flow_element+ matches all flow element.
      rule(:flow_element) { call_rule_line | if_block | case_block | assignment_line }

      # +call_rule_line+ matches calling rule.
      #
      # @example
      #   rule Test
      rule(:call_rule_line) { line(keyword_rule >> space? >> expr).as(:call_rule) }

      # +if_block+ matches +if+ conditional block.
      #
      # @example
      #   if $Var
      #     rule Test1
      #   else
      #     rule Test2
      #   end
      rule(:if_block) {
        (if_block_header >> flow_element.repeat.as(:true_elements) >> else_block.maybe >> conditional_block_end!).as(:if_block)
      }

      # +if_block_begin+ matches +if+ block condition.
      #
      # @example
      #   if $Var
      rule(:if_block_header) {
        line(keyword_if >> space? >> expr!("condition not found").as(:condition))
      }

      # +else_block+ matches +else+ block.
      #
      # @example
      #   else
      #     rule Test1
      #     rule Test2
      #     ...
      rule(:else_block) { line(keyword_else) >> flow_element.repeat.as(:else_elements) }

      # +conditional_block_end+ matches conditional block end.
      rule(:conditional_block_end) { line(keyword_end) }
      rule(:conditional_block_end!) { conditional_block_end.or_error("conditional block end not found") }

      # +case_block+ matches conditional block end.
      #
      # @example
      #   case $Var
      #   when 1
      #     rule Test1
      #   when 2
      #     rule Test2
      #   else
      #     rule Test3
      #   end
      rule(:case_block) {
        (case_block_header >> when_blocks >> else_block.maybe >> conditional_block_end!).as(:case_block)
      }

      # +case_block_begin+ matches +case+ block beginning.
      #
      # @example
      #   case $Var
      rule(:case_block_header) { line(keyword_case >> space? >> expr.as(:condition)) }

      # +when_blocks+ are +when_block+.
      rule(:when_blocks) { when_block.repeat.as(:when_blocks) }

      # +when_block+ matches +when+ block.
      #
      # @example
      #   when 1
      #     rule Test1
      #     rule Test2
      #     ...
      rule(:when_block) {
        (when_block_header >> flow_element.repeat.as(:elements)).as(:when_block)
      }

      # +when_block_begin+ matches +when+ block beginning.
      #
      # @example
      #   when 1
      rule(:when_block_header) { line(keyword_when >> space? >> expr.as(:value)) }

      # +assignment_line+ matches variable assignment line.
      #
      # @example
      #   $X := 1
      rule(:assignment_line) { line(assignment) }
    end
  end
end
