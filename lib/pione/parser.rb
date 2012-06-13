require 'pione/common'
require 'parslet'

module Pione
  class Parser < Parslet::Parser
    require 'pione/parser/syntax-error'
    require 'pione/parser/common'
    require 'pione/parser/literal'
    require 'pione/parser/feature-expr'
    require 'pione/parser/expr'
    require 'pione/parser/flow-element'
    require 'pione/parser/block'

    include Common
    include Literal
    include FeatureExpr
    include Expr
    include FlowElement
    include Block

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

    #
    # rule
    #

    rule(:rule_definitions) {
      (space? >> rule_definition >> empty_lines?).repeat
    }

    rule(:rule_header) {
      keyword_rule_header >> space >> rule_name >> line_end
    }

    rule(:rule_definition) {
      ( rule_header.as(:rule_header) >>
        rule_conditions >>
        block
        ).as(:rule_definition)
    }

    rule(:rule_conditions) {
      input_lines >>
      output_lines >>
      param_lines >>
      feature_lines
    }

    rule(:input_lines) {
      input_line.repeat(1).as(:inputs) |
      syntax_error('expect input lines', ['input_line'])
    }

    rule(:output_lines) {
      output_line.repeat.as(:outputs)
    }

    rule(:param_lines) {
      param_line.repeat.as(:params)
    }

    rule(:feature_lines) {
      feature_line.repeat.as(:features)
    }

    #
    # rule conditions
    #

    # input_line
    rule(:input_line) {
      ( space? >>
        input_header >>
        space >>
        data_expr.as(:data) >>
        line_end
        ).as(:input_line)
    }

    # input_header
    rule(:input_header) {
      (keyword_input_all | keyword_input).as(:input_header)
    }

    # output_line
    rule(:output_line) {
      ( space? >>
        output_header >>
        space >>
        data_expr.as(:data) >>
        line_end
        ).as(:output_line)
    }

    # output_header
    rule(:output_header) {
      (keyword_output_all | keyword_output).as(:output_header)
    }

    # param_line
    rule(:param_line) {
      ( space? >>
        keyword_param >>
        space >>
        variable >>
        line_end
        ).as(:param_line)
    }

    # feature_line
    rule(:feature_line) {
      ( space? >>
        keyword_feature >>
        space >>
        ( feature_expr |
          syntax_error("Need feature expression in this context.",
                       ["idenfifier"])
          ) >>
        line_end
        ).as(:feature_line)
    }
  end
end
