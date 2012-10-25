module Pione
  module Parser
    # Rule Definition is a set of parser atom for defining rule.
    module RuleDefinition
      include Parslet
      include SyntaxError
      include Common
      include Literal
      include Expr
      include FlowElement
      include Block

      # @!attribute [r] rule_definitions
      #   @return [Parslet::Atoms::Entity] toplevel element list
      rule(:rule_definitions) {
        (empty_lines? >> space? >> toplevel_element >> empty_lines?).repeat
      }

      # @!attribute [r] toplevel_element
      #   @return [Parslet::Atoms::Entity] toplevel element
      #   @example
      #     # document toplevel assignment
      #     $X := 1
      #   @example
      #     # define rule
      #     Rule Main
      #       input '*.txt'
      #       ...
      #     Flow
      #       rule SubRule
      #       ...
      #     End
      #   @example
      #     # you can write any expressions in toplevel but it is ignored
      #     1 + 1
      rule(:toplevel_element) {
        rule_definition |
        assignment |
        expr
      }

      # @!attribute [r] rule_definition
      #   @return [Parslet::Atoms::Entity] rule definition
      #   @example
      #     Rule Main
      #       input '*.txt'
      #       ...
      #     Flow
      #       rule SubRule
      #       ...
      #     End
      rule(:rule_definition) {
        ( rule_header >>
          rule_conditions >>
          block.as(:block)
        ).as(:rule_definition)
      }

      # @!attribute [r] rule_header
      #   @return [Parslet::Atoms::Entity] rule header
      #   @example
      #     Rule Main
      rule(:rule_header) {
        ( keyword_Rule >>
          space >>
          ( rule_name | syntax_error("it should be rule name", :rule_name)) >>
          line_end
        ).as(:rule_header)
      }

      # @!attribute [r] rule_conditions
      #   @return [Parslet::Atoms::Entity] rule condition list
      rule(:rule_conditions) {
        rule_condition.repeat.as(:rule_conditions)
      }

      # @!attribute [r] rule_condition
      #   @return [Parslet::Atoms::Entity] rule condition
      #   @example
      #     # input condition
      #     input '*.in'
      #   @example
      #     # output condition
      #     output '*.out'
      #   @example
      #     # param line
      #     param $VAR := "abc"
      #   @example
      #     # feature condition
      #     feature *
      rule(:rule_condition) {
        input_line |
        output_line |
        param_line |
        feature_line
      }

      #
      # rule conditions
      #

      # @!attribute [r] input_line
      #   @return [Parslet::Atoms::Entity] input line
      #   @example
      #     input '*.in'
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

      # @!attribute [r] output_line
      #   @return [Parslet::Atoms::Entity] output line
      #   @example
      #     output '*.out'
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

      # @!attribute [r] param_line
      #   @return [Parslet::Atoms::Entity] parameter line
      #   @example
      #     param $VAR := "abc"
      rule(:param_line) {
        ( space? >>
          keyword_param >>
          space >>
          ( expr.as(:expr) |
            syntax_error("it should be expr", :expr)
          ) >>
          line_end
        ).as(:param_line)
      }

      # @!attribute [r] feature_line
      #   @return [Parslet::Atoms::Entity] feature line
      #   @example
      #     feature *
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
end
