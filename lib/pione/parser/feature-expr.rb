module Pione
  class Parser
    module FeatureExpr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      # atomic_feature
      # +X
      # -X
      # ?X
      rule(:atomic_feature) {
        ((plus.as(:operator) >> identifier.as(:symbol)) |
         (minus.as(:operator) >> identifier.as(:symbol)) |
         (question.as(:operator) >> identifier.as(:symbol))
         ).as(:atomic_feature)
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
        atomic_feature |
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
