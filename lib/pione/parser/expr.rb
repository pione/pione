module Pione
  class Parser
    module Expr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      rule(:expr) {
        expr_operator_application |
        expr_element
      }

      rule(:expr_element) {
        atomic_expr |
        lparen >> expr >> rparen
      }

      rule(:atomic_expr) {
        float |
        integer |
        string |
        data_expr |
        rule_expr |
        variable
      }

      rule(:expr_operator) {
        colon >> equals |
        equals >> equals |
        exclamation >> equals |
        less_than >> equals |
        less_than |
        greater_than >> equals |
        greater_than |
        ampersand >> ampersand |
        vbar >> vbar
      }

      rule(:expr_operator_application) {
        (expr_element.as(:left) >>
         space? >>
         expr_operator.as(:operator) >>
         space? >>
         expr.as(:right)
         ).as(:expr_operator_application)
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
    end
  end
end
