require_relative '../test-util'

describe 'Transformer::FeatureExpr' do
  transformer_spec("feature_expr", :feature_expr) do
    tc('+A' => Feature::RequisiteExpr.new("A"))
    tc('-A' => Feature::BlockingExpr.new("A"))
    tc('?A' => Feature::PreferredExpr.new("A"))
    tc('^A' => Feature::PossibleExpr.new("A"))
    tc('!A' => Feature::RestrictiveExpr.new("A"))
    tc('*' => Feature.empty)
    tc('@' => Feature.boundless)
    tc '+A & +B' do
      Feature::AndExpr.new(Feature::RequisiteExpr.new("A"),
                           Feature::RequisiteExpr.new("B"))
    end
    tc '+A | +B' do
      Feature::OrExpr.new(Feature::RequisiteExpr.new("A"),
                          Feature::RequisiteExpr.new("B"))
    end
  end
end
