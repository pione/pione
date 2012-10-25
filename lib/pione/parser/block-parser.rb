module Pione
  module Parser
    # BlockParser is a set of parser atoms for rule block.
    module BlockParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include ExprParser
      include FlowElementParser

      # @!attribute [r] block
      #   +block+ matches flow block or action block.
      #   @return [Parslet::Atoms::Entity] +block+ atom
      rule(:block) {
        flow_block |
        action_block
      }

      # @!attribute [r] flow_block
      #   +flow_block+ matches flow block.
      #   @return [Parslet::Atoms::Entity] +flow_block+ atom
      #   @example
      #     Flow
      #       rule A
      #       if $X
      #         rule B
      #       end
      #     End
      rule(:flow_block) {
        ( flow_block_begin_line >>
          (flow_element.repeat(1) |
            syntax_error("flow elements not found", [:flow_element])) >>
          (block_end_line |
            syntax_error("block end not found", [:keyword_End]))
         ).as(:flow_block)
      }

      # @!attribute [r] action_block
      #   +action_block+ matches action block.
      #   @return [Parslet::Atoms::Entity] +action_block+ atom
      #   @example
      #     Action
      #       echo "abc" > out.txt
      #     End
      rule(:action_block) {
        ( action_block_begin_line >>
          ( (block_end_line.absent? >> any).repeat(1).as(:content) |
            syntax_error("empty action block", [])) >>
          ( block_end_line |
            syntax_error("block end not found", [:keyword_End]))
        ).as(:action_block)
      }

      # @!attribute [r] flow_block_begin_line
      #   +flow_block_begin_line+ matches flow block heading.
      #   @return [Parslet::Atoms::Entity] +flow_block_begin_line+ atom
      #   @example
      #     Flow
      rule(:flow_block_begin_line) {
        space? >> keyword_Flow >> str('-').repeat >> line_end
      }

      # @!attribute [r] action_block_begin_line
      #   +flow_block_begin_line+ matches action block heading.
      #   @return [Parslet::Atoms::Entity] +action_block_begin_line+ atom
      #   @example
      #     Action
      rule(:action_block_begin_line) {
        space? >> keyword_Action.as(:key) >> str('-').repeat >> line_end
      }

      # @!attribute [r] block_end_line
      #   +block_end_line+ matches block end keyword.
      #   @return [Parslet::Atoms::Entity] +block_end_line+ atom
      #   @example
      #     End
      rule(:block_end_line) {
        space? >> str('-').repeat >> keyword_End >> line_end
      }
    end
  end
end
