require 'pione/test-util'

describe 'Transformer::FeatureExpr' do
  it 'should get feature expressions' do
    a = Feature::Symbol.new('A')
    b = Feature::Symbol.new('B')
    data = {
      '+A' => Feature::RequisiteExpr.new(a),
      '-A' => Feature::BlockingExpr.new(a),
      '?A' => Feature::PreferredExpr.new(a),
      '+A & +B' =>
      Feature::AndExpr.new(Feature::RequisiteExpr.new(a),
                           Feature::RequisiteExpr.new(b)),
      '+A | +B' =>
      Feature::OrExpr.new(Feature::RequisiteExpr.new(a),
                          Feature::RequisiteExpr.new(b))
    }
    data.each do |string, val|
      res = Transformer.new.apply(Parser.new.feature_expr.parse(string))
      res.should == val
    end
  end
end
