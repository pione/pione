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
      (space? >> toplevel_element >> empty_lines?).repeat
    }

    # toplevel_element
    #   Rule abc ...
    #   $X := 1
    rule(:toplevel_element) {
      rule_definition |
      assignment
    }

    # rule_definition
    rule(:rule_definition) {
      ( rule_header >>
        rule_conditions >>
        block.as(:block)
        ).as(:rule_definition)
    }

    # rule_header
    rule(:rule_header) {
      ( keyword_Rule >>
        space >>
        ( rule_name | syntax_error("it should be rule name", :rule_name)) >>
        line_end
      ).as(:rule_header)
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

    # input_line
    rule(:input_line) {
      ( space? >>
        keyword_input >>
        space >>
        ( expr.as(:expr) |
          syntax_error("it should be data_expr", :data_expr)
        ) >>
        line_end
      ).as(:input_line)
    }

    # output_line
    rule(:output_line) {
      ( space? >>
        keyword_output >>
        space >>
        ( expr.as(:expr) |
          syntax_error("it should be data_expr", :data_expr)
        ) >>
        line_end
      ).as(:output_line)
    }

    # param_line
    rule(:param_line) {
      ( space? >>
        keyword_param >>
        space >>
        ( expr.as(:expr) |
          syntax_error("it should be data_expr", :data_expr)
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
          syntax_error("it should be feature_expr", :feature_expr)
        ) >>
        line_end
      ).as(:feature_line)
    }
  end
end
