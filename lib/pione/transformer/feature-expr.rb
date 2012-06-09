require 'pione/common'

module Pione
  class Transformer
    module FeatureExpr
      include TransformerModule

      # feature expr
      rule(:feature_expr => simple(:expr)) do
        expr
      end

      # feature conjunction
      rule(:feature_conjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        FeatureExpr::And.new(left, right)
      end

      # feature disjunction
      rule(:feature_disjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        FeatureExpr::Or.new(left, right)
      end
    end
  end
end
