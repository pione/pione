module Pione
  module Parser
    # DocumentParser is a parser for PIONE rule document.
    class DocumentParser < Parslet::Parser
      include CommonParser
      include LiteralParser
      include FeatureExprParser
      include ExprParser
      include FlowElementParser
      include BlockParser
      include RuleDefinitionParser

      #
      # root
      #

      # +toplevel_elements+ matches all toplevel elements. This is root parser
      # for reading a document.
      rule(:toplevel_elements) {
        (empty_lines? >> space? >> toplevel_element >> empty_lines?).repeat
      }
      root(:toplevel_elements)

      # +toplevel_element+ matches toplevel elements.
      rule(:toplevel_element) {
        rule_definition |
        param_block |
        param_line.as(:toplevel_param_line) |
        assignment_line.as(:toplevel_assignment_line) |
        expr_line |
        annotation_line
      }

      #
      # document statement
      #

      # document_statement
      rule(:document_statement) { package_line | require_line }
      rule(:document_statements) { document_statement.repeat.as(:document_statements) }

      # +assignment_line+ matches variable assignment lines.
      rule(:assignment_line) { line(assignment) }

      # +param_block+ matches parameter statement blocks.
      #
      # @example
      #   Param
      #     $X := 1
      #     $Y := 2
      #     $Z := 3
      #   End
      # @example Basic Paramter Block
      #   Basic Param
      #     $X := 1
      #     $Y := 2
      #     $Z := 3
      #   End
      # @example Advanced Parameter Block
      #   Advanced Param
      #     $X := 1
      #     $Y := 2
      #     $Z := 3
      #   End
      rule(:param_block) {
        (param_block_header >> param_block_body >> param_block_footer!).as(:param_block)
      }

      # +param_block_modifier+ matches all parameter block modifiers.
      rule(:param_block_modifier) { keyword_Basic | keyword_Advanced }

      # +param_block_header+ matches parameter block headers.
      rule(:param_block_header) {
        line((param_block_modifier.as(:param_type) >> space).maybe >> keyword_Param)
      }

      # +param_block_body+ matches assignments in parameter statement block.
      rule(:param_block_body) {
        (assignment_line | pad).repeat.as(:in_block_assignments)
      }

      # +param_block_footer+ matches parameter statement block footer.
      rule(:param_block_footer) { line(keyword_End) }
      rule(:param_block_footer!) { param_block_footer.or_error("it should be block end") }

      # package_line
      rule(:package_line) {
        line(keyword_package >> space >> package_name).as(:package)
      }

      # require_line
      rule(:require_line) {
        line(keyword_require >> space >> package_name).as(:require)
      }

      # +expr_line+ matches expression lines.
      rule(:expr_line) { line(expr) }
      rule(:expr_lines) { expr_line.repeat(1) }
    end
  end
end
