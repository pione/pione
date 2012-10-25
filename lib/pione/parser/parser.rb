module Pione
  module Parser
    # Parser is a parser for PIONE rule document.
    class Parser < Parslet::Parser
      include Common
      include Literal
      include FeatureExpr
      include Expr
      include FlowElement
      include Block
      include RuleDefinition

      def parse(str)
        super(str.gsub(/^#.*/, ""))
      end

      #
      # root
      #

      root(:rule_definitions)

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
    end
  end
end

