require 'pione/common'

module Pione
  class Transformer
    module FeatureExpr
      include TransformerModule

      # feature_name
      # convert into plain string
      rule(:atomic_feature =>
           { :operator => simple(:operator),
             :symbol => simple(:symbol) }
           ) do
        symbol_obj = Feature::Symbol.new(symbol.str)
        case operator
        when "+"
          Feature::RequisiteExpr.new(symbol_obj)
        when "-"
          Feature::BlockingExpr.new(symbol_obj)
        when "?"
          Feature::PreferredExpr.new(symbol_obj)
        end
      end

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
