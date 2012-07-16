require_relative '../test-util'

describe 'Model::ActionBlock' do
  it 'should be equal' do
    ActionBlock.new("eccho 'a'").should ==
      ActionBlock.new("eccho 'a'")
  end

  it 'should not be equal' do
    ActionBlock.new("eccho 'a'").should.not ==
      ActionBlock.new("eccho 'b'")
  end

  it 'should expand variables' do
    block = ActionBlock.new("{$var1} {$var2} {$var3}")
    vtable = VariableTable.new
    vtable.set(Variable.new("var1"), PioneString.new("a"))
    vtable.set(Variable.new("var2"), PioneString.new("b"))
    vtable.set(Variable.new("var3"), PioneString.new("c"))
    block.eval(vtable).should == ActionBlock.new("a b c")
  end
end

describe 'Model::FlowBlock' do
  it 'should be equal' do
    FlowBlock.new(
      CallRule.new(RuleExpr.new(Package.new("test"), "a"))
    ).should == FlowBlock.new(
      Model::CallRule.new(RuleExpr.new(Package.new("test"), "a"))
    )
  end

  it 'should not equal' do
    FlowBlock.new(
      CallRule.new(RuleExpr.new(Package.new("test"), "a"))
    ).should.not == FlowBlock.new(
      CallRule.new(RuleExpr.new(Package.new("test"), "b"))
    )
  end

  it 'should get flow elements' do
    FlowBlock.new(
      CallRule.new(RuleExpr.new(Package.new("test"), "a")),
      CallRule.new(RuleExpr.new(Package.new("test"), "b")),
      CallRule.new(RuleExpr.new(Package.new("test"), "c"))
    ).elements.should == [
      CallRule.new(RuleExpr.new(Package.new("test"), "a")),
      CallRule.new(RuleExpr.new(Package.new("test"), "b")),
      CallRule.new(RuleExpr.new(Package.new("test"), "c"))
    ]
  end
end
