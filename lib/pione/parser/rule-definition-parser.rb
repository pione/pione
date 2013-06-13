module Pione
  module Parser
    # RuleDefinitionParser is a set of parser atom for defining rule.
    module RuleDefinitionParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include ExprParser
      include FlowElementParser
      include BlockParser

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
        ( space? >>
          rule_header >>
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
        feature_line |
        constraint_line |
        annotation_line
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
          ((keyword_basic | keyword_advanced).as(:param_type) >> space).maybe >>
          keyword_param >>
          space >>
          ( expr.as(:expr) |
            syntax_error("it should be expr", :expr)
          ).as(:param_expr) >>
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

      rule(:constraint_line) {
        ( space? >>
          keyword_constraint >>
          space? >>
          ( expr.as(:expr) |
            syntax_error("it should be expr", :expr)
          ) >>
          line_end
        ).as(:constraint_line)
      }

      rule(:annotation_line) {
        ( space? >>
          atmark >>
          space? >>
          ( expr.as(:expr) | syntax_error("it should be expr", :expr)) >>
          line_end
        ).as(:annotation_line)
      }
    end
  end
end
