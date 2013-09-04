require_relative '../test-util'

describe 'Model::RuleExpr' do
  before do
    @a = RuleExpr.new(PackageExpr.new("main"), "a")
    @b = RuleExpr.new(PackageExpr.new("main"), "b")
  end

  it 'should be equal' do
    @a.should == RuleExpr.new(PackageExpr.new("main"), "a")
  end

  it 'should be not equal' do
    @a.should.not == @b
  end

  test_pione_method("rule-expr")
end
