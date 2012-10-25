module Pione
  module Parser
    # FlowElementParser is a set of parser atoms for flow elements.
    module FlowElementParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include ExprParser

      # @!attribute [r] flow_element
      #   +flow_element+ matches flow element.
      #   @return [Parslet::Atoms::Entity] +flow_element+ atom
      #   @example
      #     # rule calling
      #     rule A
      #   @example
      #     # if block
      #     if $VAR
      #       rule A
      #     end
      #   @example
      #     # case block
      #     case $VAR
      #     when "A"
      #       rule A
      #     when "B"
      #       rule B
      #     end
      #   @example
      #     # assignment
      #     $VAR := true
      rule(:flow_element) {
        call_rule_line |
        if_block |
        case_block |
        assignment_line
      }

      # @!attribute [r] call_rule_line
      #   +call_rule_line+ matches calling rule.
      #   @return [Parslet::Atoms::Entity] +call_rule_line+ atom
      #   @example
      #     rule Test
      rule(:call_rule_line) {
        ( space? >>
          keyword_rule >>
          space? >>
          expr >>
          line_end
        ).as(:call_rule)
      }

      # @!attribute [r] if_block
      #   +if_block+ matches +if+ conditional block.
      #   @return [Parslet::Atoms::Entity] +if_block+ atom
      #   @example
      #     if $Var
      #       rule Test1
      #     else
      #       rule Test2
      #     end
      rule(:if_block) {
        ( if_block_begin >>
          flow_element.repeat.as(:if_true_elements) >>
          else_block.maybe.as(:if_else_block) >>
          conditional_block_end
        ).as(:if_block)
      }

      # @!attribute [r] if_block_begin
      #   +if_block_begin+ matches +if+ block condition.
      #   @return [Parslet::Atoms::Entity] +if_block_begin+ atom
      #   @example
      #     if $Var
      rule(:if_block_begin) {
        space? >>
        keyword_if >>
        space? >>
        expr.as(:condition) >>
        line_end
      }

      # @!attribute [r] else_block
      #   +else_block+ matches +else+ block.
      #   @return [Parslet::Atoms::Entity] +else_block+ atom
      #   @example
      #     else
      #       rule Test1
      #       rule Test2
      #       ...
      rule(:else_block) {
        ( space? >>
          keyword_else >>
          line_end >>
          flow_element.repeat.as(:elements)
        ).as(:else_block)
      }

      # @!attribute [r] conditional_block_end
      #   +conditional_block_end+ matches conditional block end.
      #   @return [Parslet::Atoms::Entity] +conditional_block_end+ atom
      #   @example
      #     end
      rule(:conditional_block_end) {
        space? >> keyword_end >> line_end
      }

      # @!attribute [r] case_block
      #   +case_block+ matches conditional block end.
      #   @return [Parslet::Atoms::Entity] +case_block+ atom
      #   @example
      #     case $Var
      #     when 1
      #       rule Test1
      #     when 2
      #       rule Test2
      #     else
      #       rule Test3
      #     end
      rule(:case_block) {
        ( case_block_begin >>
          when_block.repeat.as(:when_blocks) >>
          else_block.maybe.as(:case_else_block) >>
          conditional_block_end
        ).as(:case_block)
      }

      # @!attribute [r] case_block_begin
      #   +case_block_begin+ matches +case+ block beginning.
      #   @return [Parslet::Atoms::Entity] +case_block_begin+ atom
      #   @example
      #     case $Var
      rule(:case_block_begin) {
        space? >>
        keyword_case >>
        space? >>
        expr.as(:condition) >>
        line_end
      }

      # @!attribute [r] when_block
      #   +when_block+ matches +when+ block.
      #   @return [Parslet::Atoms::Entity] +when_block+ atom
      #   @example
      #     when 1
      #       rule Test1
      #       rule Test2
      #       ...
      rule(:when_block) {
        ( when_block_begin >>
          flow_element.repeat.as(:elements)
        ).as(:when_block)
      }

      # @!attribute [r] when_block_begin
      #   +when_block_begin+ matches +when+ block beginning.
      #   @return [Parslet::Atoms::Entity] +when_block_begin+ atom
      #   @example
      #     when 1
      rule(:when_block_begin) {
        space? >>
        keyword_when >>
        space? >>
        expr.as(:value) >>
        line_end
      }

      # @!attribute [r] assignment_line
      #   +assignment_line+ matches variable assignment line.
      #   @return [Parslet::Atoms::Entity] +assignment_line+ atom
      #   @example
      #     $X := 1
      rule(:assignment_line) {
        space? >>
        assignment >>
        line_end
      }
    end
  end
end
