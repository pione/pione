module InnocentWhite
  class Parser
    module FeatureExpr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      rule(:feature_expr) {
        feature_conjunction |
        feature_disjunction |
        feature_element
      }

      rule(:feature_element) {
        feature_name |
        lparen >> feature_expr >> rparen
      }

      rule(:feature_conjunction) {
        feature_element.as(:left) >>
        space? >>
        ampersand >>
        space? >>
        feature_expr.as(:right)
      }

      rule(:feature_disjunction) {
        feature_element.as(:left) >>
        space? >>
        vbar >>
        space? >>
        feature_expr.as(:right)
      }
    end
  end
end
