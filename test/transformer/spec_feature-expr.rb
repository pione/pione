require 'pione/test-util'

describe 'Transformer::FeatureExpr' do
  it 'should get feature expressions' do
    data = {
      '+A' => FeatureExpr.new('A', :requisite),
      '-A' => FeatureExpr.new('A', :exclusive),
      '?A' => FeatureExpr.new('A', :preferred),
      '+A & +A' =>
      FeatureExpr.new('abc', :requisite).and('def', :requisite)
    }
    data.each do |string, val|
      res = Transformer.new.apply(Parser.new.feature_expr.parse(string))
      res.should == val
    end
  end
end
