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

      root(:toplevel_elements)

      # @!method toplevel_elements
      #
      # Return +toplevel_elements+ parser. This is root parser for reading a
      # document.
      #
      # @return [Parslet::Atoms::Entity]
      #   +toplevel_elements+ parser
      rule(:toplevel_elements) {
        (empty_lines? >> space? >> toplevel_element >> empty_lines?).repeat
      }

      # @!method toplevel_element
      #
      # Return +toplevel_element+ parser.
      #
      # @return [Parslet::Atoms::Entity]
      #   +toplevel_element+ parser
      #
      # @example
      #   # document toplevel assignment
      #   DocumentParser.toplevel_element.parse("$X := 1")
      # @example
      #   # define rule
      #   DocumentParser.new.toplevel_element.parse <<TXT
      #     Rule Main
      #       input '*.txt'
      #       ...
      #     Flow
      #       rule SubRule
      #       ...
      #     End
      #   TXT
      # @example
      #   # you can write any expressions in toplevel but it is ignored
      #   DocumentParser.new.toplevel_element.parse("1 + 1")
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

      rule(:document_statements) {
        document_statement.repeat.as(:document_statements)
      }

      # document_statement
      rule(:document_statement) {
        package_line |
        require_line
      }

      # @!method assignment_line
      #
      # Return +assignment_line+ parser.
      #
      # @return [Parslet::Atoms::Entity]
      #   +assignment_line+ parser
      #
      # @example
      #   DocumentParser.new.assignment_line("$X := 1")
      rule(:assignment_line) {
        space? >> assignment >> line_end
      }

      # @!method param_block
      #
      # Return +param_block+ parser.
      #
      # @return [Parslet::Atoms::Entity]
      #   +param block+ parser
      #
      # @example
      #   DocumentParser.new.param_block <<TXT
      #     Param
      #       $X := 1
      #       $Y := 2
      #       $Z := 3
      #     End
      #   TXT
      rule(:param_block) {
        ( space? >>
          keyword_Param >>
          line_end >>
          (assignment_line | pad).repeat >>
          (keyword_End | syntax_error("it should be block end", :keyword_End)) >>
          line_end
        ).as(:param_block)
      }

      # package_line
      rule(:package_line) {
        ( space? >>
          keyword_package >>
          space >>
          package_name >>
          line_end
        ).as(:package)
      }

      # require_line
      rule(:require_line) {
        ( space? >>
          keyword_require >>
          space >>
          package_name >>
          line_end
        ).as(:require)
      }

      rule(:expr_line) {
        space? >> expr >> line_end
      }
    end
  end
end
