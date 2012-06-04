require 'innocent-white/test-util'

describe 'Transformer::FeatureExpr' do
  it 'should get feature expressions' do
    data = {
      '+abc' => FeatureExpr.new('abc', :requisite),
      '-abc' => FeatureExpr.new('abc', :exclusive),
      '?abc' => FeatureExpr.new('abc', :preferred),
      '+abc & +def' =>
      FeatureExpr.new('abc', :requisite).and('def', :requisite)
    }
    data.each do |string, val|
      res = Transformer.new.apply(Parser.new.feature_expr.parse(string))
      res.should == val
    end
  end
end
