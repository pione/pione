require 'innocent-white/common'

module InnocentWhite
  class Transformer
    module FeatureExpr
      include TransformerModule

      rule(:feature_conjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        left.and(right)
      end

      rule(:feature_disjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        left.or(right)
      end
    end
  end
end
