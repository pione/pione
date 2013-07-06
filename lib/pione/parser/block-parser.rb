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

      # +block+ parser matches all blocks of PIONE.
      rule(:block) {
        (flow_block | action_block | empty_block).or_error("block not found")
      }

      # +flow_block+ parser matches flow block.
      #
      # @example
      #   Flow
      #     rule A
      #     if $X
      #       rule B
      #     end
      #   End
      rule(:flow_block) {
        (flow_block_header >> flow_elements >> block_end_line!).as(:flow_block)
      }

      # +flow_block_header+ parser matches flow block heading.
      rule(:flow_block_header) { line(keyword_Flow) }

      # +action_block+ parser matches action block.
      #
      # @example
      #   Action
      #     echo "abc" > out.txt
      #   End
      rule(:action_block) {
        (action_block_header >> action_block_content >> block_end_line!).as(:action_block)
      }

      # +flow_block_header+ parser matches action block heading.
      rule(:action_block_header) { line(keyword_Action.as(:key)) }

      # +action_block_content+ matches action block contents.
      rule(:action_block_content) { (block_end_line.absent? >> any).repeat(1).as(:content) }

      # +empty_block+ parser matches empty block.
      rule(:empty_block) { block_end_line.as(:empty_block) }

      # +block_end_line+ parser matches block end keyword.
      rule(:block_end_line) { line(keyword_End) }
      rule(:block_end_line!) { block_end_line.or_error("block end not found") }
    end
  end
end
