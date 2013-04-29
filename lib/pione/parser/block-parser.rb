module Pione
  module Parser
    # BlockParser is a set of parsers for rule block.
    module BlockParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include ExprParser
      include FlowElementParser

      # @!method block
      #   +block+ parser matches all blocks of PIONE.
      #
      #   @return [Parslet::Atoms::Entity]
      #     +block+ parser
      rule(:block) {
        flow_block |
        action_block |
        empty_block |
        syntax_error("block not found", [:block])
      }

      # @!method flow_block
      #   +flow_block+ parser matches flow block.
      #
      #   @return [Parslet::Atoms::Entity]
      #     +flow_block+ parser
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

      # @!method action_block
      #   +action_block+ parser matches action block.
      #
      #   @return [Parslet::Atoms::Entity]
      #     +action_block+ parser
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

      # @!method empty_block
      #   +empty_block+ parser matches empty block.
      #   @return [Parslet::Atoms::Entity]
      #     +empty_block+ parser
      #   @example
      #     End
      rule(:empty_block) {
        block_end_line.as(:empty_block)
      }

      # @!method flow_block_begin_line
      #   +flow_block_begin_line+ parser matches flow block heading.
      #
      #   @return [Parslet::Atoms::Entity]
      #     +flow_block_begin_line+ parser
      #   @example
      #     Flow
      rule(:flow_block_begin_line) {
        space? >> keyword_Flow >> str('-').repeat >> line_end
      }

      # @!method action_block_begin_line
      #   +flow_block_begin_line+ parser matches action block heading.
      #
      #   @return [Parslet::Atoms::Entity]
      #     +action_block_begin_line+ parser
      #   @example
      #     Action
      rule(:action_block_begin_line) {
        space? >> keyword_Action.as(:key) >> str('-').repeat >> line_end
      }

      # @!method block_end_line
      #   +block_end_line+ parser matches block end keyword.
      #
      #   @return [Parslet::Atoms::Entity]
      #     +block_end_line+ parser
      #   @example
      #     End
      rule(:block_end_line) {
        space? >> str('-').repeat >> keyword_End >> line_end
      }
    end
  end
end
