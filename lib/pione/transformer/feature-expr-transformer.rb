module Pione
  module Transformer
    # FeatureExprTransformer is a transformer for syntax tree of feature
    # expressions.
    module FeatureExprTransformer
      include TransformerModule

      # Transform +:feature_name+ as feature expression model corresponding to
      # the operator.
      rule(:atomic_feature =>
           { :operator => simple(:operator),
             :symbol => simple(:symbol) }
           ) do
        case operator
        when "+"
          Feature::RequisiteExpr.new(symbol.str)
        when "-"
          Feature::BlockingExpr.new(symbol.str)
        when "?"
          Feature::PreferredExpr.new(symbol.str)
        when "^"
          Feature::PossibleExpr.new(symbol.str)
        when "!"
          Feature::RestrictiveExpr.new(symbol.str)
        end
      end

      # Transform +:atomic_feature+ as empty feature or boundless feature.
      rule(:atomic_feature => {:symbol => simple(:symbol)}) {
        case symbol
        when "*"
          Feature.empty
        when "@"
          Feature.boundless
        end
      }

      # Extract the content of +:feature_expr+.
      rule(:feature_expr => simple(:expr)) do
        expr
      end

      # Transform +:feature conjunction+ as Feature::AndExpr.
      rule(:feature_conjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        Feature::AndExpr.new(left, right)
      end

      # Transform +:feature_disjunction+ as Feature::OrExpr.
      rule(:feature_disjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        Feature::OrExpr.new(left, right)
      end
    end
  end
end
