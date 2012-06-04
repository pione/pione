require 'innocent-white/common'

module InnocentWhite
  class Transformer
    module FeatureExpr
      include TransformerModule

      rule(:feature_expr => simple(:expr)) do
        expr
      end

      rule(:feature_conjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        FeatureExpr::And.new(left, right)
      end

      rule(:feature_disjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        FeatureExpr::Or.new(left, right)
      end
    end
  end
end
