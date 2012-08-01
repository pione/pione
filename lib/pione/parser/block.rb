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
        ( flow_block_begin_line >>
          (flow_element.repeat(1) |
            syntax_error("empty flow block", [:flow_element])) >>
          (block_end_line |
            syntax_error("block end not found", [:keyword_End]))
         ).as(:flow_block)
      }

      # action_block
      rule(:action_block) {
        ( action_block_begin_line >>
          ( (block_end_line.absent? >> any).repeat(1).as(:content) |
            syntax_error("empty action block", [])) >>
          ( block_end_line |
            syntax_error("block end not found", [:keyword_End]))
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
        space? >> keyword_Action.as(:key) >> str('-').repeat >> line_end
      }

      # block_end_line
      #   End
      rule(:block_end_line) {
        space? >> str('-').repeat >> keyword_End >> line_end
      }
    end
  end
end
