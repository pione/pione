require_relative '../test-util'

describe 'Pione::Transformer::FeatureExprTransformer' do
  transformer_spec("feature_expr", :feature_expr) do
    test('+A', Feature::RequisiteExpr.new("A"))
    test('-A', Feature::BlockingExpr.new("A"))
    test('?A', Feature::PreferredExpr.new("A"))
    test('^A', Feature::PossibleExpr.new("A"))
    test('!A', Feature::RestrictiveExpr.new("A"))
    test('*', Feature.empty)
    test('@', Feature.boundless)

    test '+A & +B' do |expr|
      expr.should.kind_of Feature::AndExpr
      expr.elements.size.should == 2
      expr.elements.should.include Feature::RequisiteExpr.new("A")
      expr.elements.should.include Feature::RequisiteExpr.new("B")
    end

    test '+A | +B' do |expr|
      expr.should.kind_of Feature::OrExpr
      expr.elements.size.should == 2
      expr.elements.should.include Feature::RequisiteExpr.new("A")
      expr.elements.should.include Feature::RequisiteExpr.new("B")
    end
  end
end
