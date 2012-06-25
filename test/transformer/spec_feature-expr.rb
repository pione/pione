require 'test-util'

describe 'Transformer::FeatureExpr' do
  a = Feature::Symbol.new('A')
  b = Feature::Symbol.new('B')

  transformer_spec("feature_expr", :feature_expr) do
    tc('+A' => Feature::RequisiteExpr.new(a))
    tc('-A' => Feature::BlockingExpr.new(a))
    tc('?A' => Feature::PreferredExpr.new(a))
    tc '+A & +B' do
      Feature::AndExpr.new(Feature::RequisiteExpr.new(a),
                           Feature::RequisiteExpr.new(b))
    end
    tc '+A | +B' do
      Feature::OrExpr.new(Feature::RequisiteExpr.new(a),
                          Feature::RequisiteExpr.new(b))
    end
  end
end
