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

      # +rule_definition+ matches rule definition blocks.
      #
      # @example
      #   Rule Main
      #     input '*.txt'
      #     ...
      #   Flow
      #     rule SubRule
      #     ...
      #   End
      rule(:rule_definition) {
        (rule_header >> rule_conditions! >> block.as(:block)).as(:rule_definition)
      }

      # +rule_header+ matches rule headers.
      rule(:rule_header) {
        line(keyword_Rule >> space >> rule_name.or_error("should be rule name")).as(:rule_header)
      }

      # @example input condition
      #   input '*.in'
      # @example output condition
      #   output '*.out'
      # @example param line
      #   param $VAR := "abc"
      # @example feature condition
      #   feature *
      rule(:rule_condition) {
        input_line | output_line | param_line | feature_line |
        constraint_line | annotation_line
      }
      rule(:rule_conditions) { (rule_condition | empty_line).repeat(1).as(:rule_conditions) }
      rule(:rule_conditions!) { rule_conditions.or_error("should be rule conditions") }

      #
      # rule conditions
      #

      # +input_line+ matches input condition lines.
      #
      # @example
      #   input '*.in'
      rule(:input_line) {
        line(keyword_input >> space >> expr!.as(:expr)).as(:input_line)
      }

      # +output_line+ matches output condition lines.
      #
      # @example
      #   output '*.out'
      rule(:output_line) {
        line(keyword_output >> space >> expr!.as(:expr)).as(:output_line)
      }

      # basic or advanced modifier
      rule(:param_modifier) { keyword_basic | keyword_advanced }

      # +param_line+ matches parameter lines.
      #
      # @example
      #   param $var := "abc"
      # @example basic parameter
      #   basic param $var := "abc"
      # @example advanced parameter
      #   adevanced param $var := "abc"
      rule(:param_line) {
        modifier = (param_modifier.as(:type) >> space).maybe
        expr = (assignment | variable).or_error("should be assignment or variable").as(:param_expr)
        line(modifier >> keyword_param >> space >> expr).as(:param_line)
      }

      # +feature_line+ matches feature lines.
      rule(:feature_line) {
        line(keyword_feature >> space >> expr!.as(:expr)).as(:feature_line)
      }

      # +constraint_line+ matches constraint lines.
      rule(:constraint_line) {
        line(keyword_constraint >> space? >> expr!.as(:expr)).as(:constraint_line)
      }

      # +annotation_line+ matches annotation lines.
      rule(:annotation_line) {
        line(atmark >> space? >> expr!.as(:expr)).as(:annotation_line)
      }
    end
  end
end
