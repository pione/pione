require_relative '../test-util'

describe 'Model::CallRule' do
  it 'should be equal' do
    CallRule.new(RuleExpr.new(PackageExpr.new("main"), "a")).should ==
      CallRule.new(RuleExpr.new(PackageExpr.new("main"), "a"))
  end

  it 'should be not equal' do
    CallRule.new(RuleExpr.new(PackageExpr.new("main"), "a")).should.not ==
      CallRule.new(RuleExpr.new(PackageExpr.new("main"), "b"))
  end

  it 'should eval' do
    a = CallRule.new(Variable.new("a"))
    a.eval(VariableTable.new(
        Variable.new("a") =>
        RuleExpr.new(PackageExpr.new("main"), "b")
    )).should == CallRule.new(
      RuleExpr.new(PackageExpr.new("main"), "b")
    )
  end
end
