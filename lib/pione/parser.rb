module Pione
  # Parser is a parser for PIONE rule document.
  class Parser < Parslet::Parser
    require 'pione/parser/syntax-error'
    require 'pione/parser/common'
    require 'pione/parser/literal'
    require 'pione/parser/feature-expr'
    require 'pione/parser/expr'
    require 'pione/parser/flow-element'
    require 'pione/parser/block'
    require 'pione/parser/rule-definition'

    include Common
    include Literal
    include FeatureExpr
    include Expr
    include FlowElement
    include Block
    include RuleDefinition

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
