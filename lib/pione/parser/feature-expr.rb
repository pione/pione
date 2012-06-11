module Pione
  class Parser
    module FeatureExpr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      # feature_name
      # +X
      # -X
      # ?X
      rule(:feature_name) {
        ((plus.as(:feature_mark) >> identifier.as(:identifier)) |
         (minus.as(:feature_mark) >> identifier.as(:identifier)) |
         (question.as(:feature_mark) >> identifier.as(:identifier))
         ).as(:feature_name)
      }

      # feature_expr
      # +X & +Y
      # +X | +Y
      rule(:feature_expr) {
        (feature_conjunction |
         feature_disjunction |
         feature_element).as(:feature_expr)
      }

      # feature_element
      # +X
      # (+X)
      rule(:feature_element) {
        feature_name |
        lparen >> feature_expr >> rparen
      }

      # feature_conjunction
      # +X & +Y
      rule(:feature_conjunction) {
        (feature_element.as(:left) >>
         space? >>
         ampersand >>
         space? >>
         feature_expr.as(:right)
         ).as(:feature_conjunction)
      }

      # feature_disjunction
      # +X | +Y
      rule(:feature_disjunction) {
        (feature_element.as(:left) >>
         space? >>
         vbar >>
         space? >>
         feature_expr.as(:right)
         ).as(:feature_disjunction)
      }
    end
  end
end
