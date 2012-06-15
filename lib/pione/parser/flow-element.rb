module Pione
  class Parser
    module FlowElement
      include Parslet
      include SyntaxError
      include Common
      include Literal
      include Expr

      # flow_element
      rule(:flow_element) {
        call_rule_line |
        if_block |
        case_block |
        assignment
        #|
        #error('Found a bad flow element',
        #      ['rule_call_line',
        #       'condition_block'])
      }

      # call_rule_line:
      #   rule Test
      rule(:call_rule_line) {
        (space? >>
         keyword_rule >>
         space? >>
         rule_expr >>
         line_end
         ).as(:call_rule)
      }

      # if_block:
      #   if $Var
      #     rule Test1
      #   else
      #     rule Test2
      #   end
      rule(:if_block) {
        (if_block_begin >>
         flow_element.repeat.as(:if_true_elements) >>
         if_block_else.maybe >>
         if_block_end).as(:if_block)
      }

      # if_block_begin:
      #   if $Var
      rule(:if_block_begin) {
        space? >>
        keyword_if >>
        space? >>
        expr.as(:condition) >>
        line_end
      }

      # if_block_else:
      #   else
      #     rule Test1
      #     rule Test2
      #     ...
      rule(:if_block_else) {
        space? >>
        keyword_else >>
        line_end >>
        flow_element.repeat.as(:if_false_elements)
      }

      # if_block_end
      #   end
      rule(:if_block_end) {
        space? >> keyword_end >> line_end
      }

      # case_block:
      #   case $Var
      #   when 1
      #     rule Test1
      #   when 2
      #     rule Test2
      #   else
      #     rule Test3
      #   end
      rule(:case_block) {
        (case_block_begin >>
         when_block.repeat.as(:when_block) >>
         if_block_else.maybe >>
         if_block_end
         ).as(:case_block)
      }

      # case_block_begin:
      #   case $Var
      rule(:case_block_begin) {
        space? >>
        keyword_case >>
        space? >>
        expr >>
        line_end
      }

      # when_block:
      #   when 1
      #     rule Test1
      #     rule Test2
      #     ...
      rule(:when_block) {
        when_block_begin >>
        flow_element.repeat.as(:elements)
      }

      # when_block_begin:
      #   when 1
      rule(:when_block_begin) {
        space? >>
        keyword_when >>
        space? >>
        expr.as(:when) >>
        line_end
      }

      # assignment:
      #   $X := 1
      rule(:assignment) {
        (space? >>
         variable.as(:symbol) >>
         space? >>
         colon >> equals >>
         space? >>
         expr.as(:value) >>
         line_end).as(:assignment)
      }
    end
  end
end
