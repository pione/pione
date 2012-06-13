module Pione
  class Parser
    module Expr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      rule(:expr) {
        float |
        integer |
        data_expr |
        rule_expr |
        string |
        variable |
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
    end
  end
end
