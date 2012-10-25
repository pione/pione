module Pione
  module Transformer
    module FeatureExprTransformer
      include TransformerModule

      # feature_name
      # convert into plain string
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
      rule(:atomic_feature => {:symbol => simple(:symbol)}) {
        case symbol
        when "*"
          Feature.empty
        when "@"
          Feature.boundless
        end
      }

      # feature expr
      rule(:feature_expr => simple(:expr)) do
        expr
      end

      # feature conjunction
      rule(:feature_conjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        Feature::AndExpr.new(left, right)
      end

      # feature disjunction
      rule(:feature_disjunction => {
             :left => simple(:left),
             :right => simple(:right)
           }) do
        Feature::OrExpr.new(left, right)
      end
    end
  end
end
