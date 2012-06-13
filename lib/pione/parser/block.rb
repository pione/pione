module Pione
  class Parser
    module Block
      include Parslet
      include SyntaxError
      include Common
      include Literal
      include Expr
      include FlowElement

      # block
      rule(:block) {
        flow_block |
        action_block #|
        #error("Found bad block.", ['flow block', 'action block'])
      }

      # flow_block
      rule(:flow_block) {
        (flow_block_begin_line >>
         flow_element.repeat >>
         block_end_line
         ).as(:flow_block)
      }

      # action_block
      rule(:action_block) {
        (action_block_begin_line >>
         (block_end_line.absent? >> any).repeat.as(:body) >>
         block_end_line
         ).as(:action_block)
      }

      # flow_block_begin_line
      #   Begin
      rule(:flow_block_begin_line) {
        space? >> keyword_Flow >> str('-').repeat >> line_end
      }

      # action_block_begin_line
      #   Action
      rule(:action_block_begin_line) {
        space? >> keyword_Action >> str('-').repeat >> line_end
      }

      # block_end_line
      #   End
      rule(:block_end_line) {
        space? >> str('-').repeat >> keyword_End >> line_end
      }
    end
  end
end
