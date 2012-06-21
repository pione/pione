class Pione::Parser
  module RuleDefinition
    include Parslet
    include SyntaxError
    include Common
    include Literal
    include Expr
    include FlowElement
    include Block

    # rule_definitions
    rule(:rule_definitions) {
      (space? >> rule_definition >> empty_lines?).repeat
    }

    # rule_header
    rule(:rule_header) {
      keyword_rule_header >> space >> rule_name >> line_end
    }

    # rule_definition
    rule(:rule_definition) {
      ( rule_header.as(:rule_header) >>
        rule_conditions >>
        block
        ).as(:rule_definition)
    }

    # rule_conditions
    rule(:rule_conditions) {
      rule_condition.repeat.as(:rule_conditions)
    }

    # rule_condition
    rule(:rule_condition) {
      input_line |
      output_line |
      param_line |
      feature_line
    }

    #
    # rule conditions
    #

    # input_header
    rule(:input_header) {
      (keyword_input_all | keyword_input).as(:input_header)
    }

    # input_line
    rule(:input_line) {
      (space? >>
       input_header >>
       space >>
       (expr.as(:expr) |
        syntax_error("expected expr in input_line context",
                     [:expr])
        ) >>
       line_end
       ).as(:input_line)
    }

    # output_header
    rule(:output_header) {
      (keyword_output_all | keyword_output).as(:output_header)
    }

    # output_line
    rule(:output_line) {
      ( space? >>
        output_header >>
        space >>
        (expr.as(:expr) |
         syntax_error("expected expr in output_line context",
                      [:expr])
         ) >>
        line_end
        ).as(:output_line)
    }

    # param_line
    rule(:param_line) {
      ( space? >>
        keyword_param >>
        space >>
        (variable.as(:variable) |
         syntax_error("expected variable in param_line context",
                      [:variable])
         ) >>
        line_end
        ).as(:param_line)
    }

    # feature_line
    rule(:feature_line) {
      ( space? >>
        keyword_feature >>
        space >>
        ( expr.as(:expr) |
          syntax_error("Need feature expression in feature_line context.",
                       [:expr])
          ) >>
        line_end
        ).as(:feature_line)
    }
  end
end
