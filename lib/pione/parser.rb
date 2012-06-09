require 'pione/common'
require 'parslet'

module Pione
  class Parser < Parslet::Parser
    require 'pione/parser/syntax-error'
    require 'pione/parser/common'
    require 'pione/parser/literal'
    require 'pione/parser/feature-expr'

    include Common
    include Literal
    include FeatureExpr

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

    #
    # expression
    #

    rule(:expr) {
      float |
      integer |
      data_expr |
      rule_expr |
      string |
      paren_expr
    }

    rule(:paren_expr) {
      lparen >> expr >> rparen
    }

    rule(:data_expr) {
      (data_name >> attributions?).as(:data_expr)
    }

    rule(:rule_expr) {
      (rule_name >> attributions?).as(:rule_expr)
    }

    rule(:attributions?) {
      attribution.repeat.as(:attributions)
    }

    rule(:attribution) {
      dot >>
      attribution_name >>
      attribution_arguments.maybe
    }

    # attribution_name
    rule(:attribution_name) {
      identifier.as(:attribution_name)
    }

    rule(:attribution_arguments) {
      lparen >>
      space? >>
      attribution_argument_element.repeat.as(:arguments) >>
      space? >>
      rparen
    }

    rule(:attribution_argument_element) {
      expr >> attribution_argument_element_rest.repeat
    }

    rule(:attribution_argument_element_rest) {
      space? >> comma >> space? >> expr
    }

    #
    # block
    #

    rule(:block) {
      flow_block |
      action_block #|
      #error("Found bad block.", ['flow block', 'action block'])
    }

    rule(:flow_block) {
      (flow_block_begin_line >>
       flow_element.repeat >>
       block_end_line
       ).as(:flow_block)
    }

    rule(:action_block) {
      (action_block_begin_line >>
       (block_end_line.absent? >> any).repeat.as(:body) >>
       block_end_line
       ).as(:action_block)
    }

    rule(:flow_block_begin_line) {
      space? >> keyword_flow_block_begin >> str('-').repeat(3) >> line_end
    }

    rule(:action_block_begin_line) {
      space? >> keyword_action_block_begin >> str('-').repeat(3) >> line_end
    }

    rule(:block_end_line) {
      space? >> str('-').repeat(3) >> keyword_block_end >> line_end
    }

    #
    # flow element
    #

    rule(:flow_element) {
      rule_call_line |
      condition_block #|
      #error('Found a bad flow element',
      #      ['rule_call_line',
      #       'condition_block'])
    }

    rule(:rule_call_line) {
      (space? >>
       keyword_call_rule >>
       space? >>
       rule_expr >>
       line_end
       ).as(:rule_call)
    }

    rule(:condition_block) {
      if_block |
      case_block
    }

    rule(:if_block) {
      (if_block_begin >>
       flow_element.repeat.as(:true_elements) >>
       if_block_else.maybe >>
       if_block_end).as(:if_block)
    }

    rule(:if_block_begin) {
      space? >>
      keyword_if >>
      space? >>
      expr >>
      line_end
    }

    rule(:if_block_else) {
      space? >>
      keyword_else >>
      line_end >>
      flow_element.repeat.as(:else_elements)
    }

    rule(:if_block_end) {
      space? >> keyword_end >> line_end
    }

    rule(:case_block) {
      (case_block_begin >>
       when_block.repeat.as(:when_block) >>
       if_block_else.maybe >>
       if_block_end
       ).as(:case_block)
    }

    rule(:case_block_begin) {
      space? >>
      keyword_case >>
      space? >>
      expr >>
      line_end
    }

    rule(:when_block) {
      when_block_begin >>
      flow_element.repeat.as(:elements)
    }

    rule(:when_block_begin) {
      space? >>
      keyword_when >>
      space? >>
      expr.as(:when) >>
      line_end
    }

  end
end
