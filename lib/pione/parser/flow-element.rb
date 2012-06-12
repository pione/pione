module Pione
  module Parser
    module FlowElement
      include Parslet::Parser

      #
      # flow element
      #

      rule(:flow_element) {
        rule_call_line |
        condition_block #|
        #error('Found a bad flow element',
        #      ['rule_call_line',
        #       'condition_block'])
      }

      rule(:rule_call_line) {
        (space? >>
         keyword_call_rule >>
         space? >>
         rule_expr >>
         line_end
         ).as(:rule_call)
      }

      rule(:condition_block) {
        if_block |
        case_block
      }

      rule(:if_block) {
        (if_block_begin >>
         flow_element.repeat.as(:true_elements) >>
         if_block_else.maybe >>
         if_block_end).as(:if_block)
      }

      rule(:if_block_begin) {
        space? >>
        keyword_if >>
        space? >>
        expr >>
        line_end
      }

      rule(:if_block_else) {
        space? >>
        keyword_else >>
        line_end >>
        flow_element.repeat.as(:else_elements)
      }

      rule(:if_block_end) {
        space? >> keyword_end >> line_end
      }

      rule(:case_block) {
        (case_block_begin >>
         when_block.repeat.as(:when_block) >>
         if_block_else.maybe >>
         if_block_end
         ).as(:case_block)
      }

      rule(:case_block_begin) {
        space? >>
        keyword_case >>
        space? >>
        expr >>
        line_end
      }

      rule(:when_block) {
        when_block_begin >>
        flow_element.repeat.as(:elements)
      }

      rule(:when_block_begin) {
        space? >>
        keyword_when >>
        space? >>
        expr.as(:when) >>
        line_end
      }
    end
  end
end
