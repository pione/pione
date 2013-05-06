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
    vtable.set(Variable.new("var1"), "a".to_pione)
    vtable.set(Variable.new("var2"), "b".to_pione)
    vtable.set(Variable.new("var3"), "c".to_pione)
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

  it 'should evaluate and get call-rule elements' do
    x = CallRule.new(RuleExpr.new(Package.new("test"), "x"))
    y = CallRule.new(RuleExpr.new(Package.new("test"), "y"))
    z = CallRule.new(RuleExpr.new(Package.new("test"), "z"))
    vtable = VariableTable.new
    block = FlowBlock.new(
      Assignment.new(Variable.new("X"), Variable.new("Y")),
      Assignment.new(Variable.new("Y"), Variable.new("Z")),
      ConditionalBlock.new(
        Variable.new("A"),
        { PioneBooleanSequence.new([PioneBoolean.true]) =>
          FlowBlock.new(Assignment.new(Variable.new("Z"), PioneIntegerSequence.new([1.to_pione]))),
        }
      ),
      Assignment.new(Variable.new("A"), PioneBooleanSequence.new([PioneBoolean.true])),
      ConditionalBlock.new(
        Message.new("==", Variable.new("Z"), PioneIntegerSequence.new([1.to_pione])),
        { PioneBooleanSequence.new([PioneBoolean.true]) => FlowBlock.new(z) }
      ),
      x,
      y
    )
    new_block = block.eval(vtable)
    new_block.elements.should.include x
    new_block.elements.should.include y
    new_block.elements.should.include z
    new_block.elements.each{|rule| rule.should.kind_of(CallRule)}
  end
end

describe 'Model::ConditionalBlock' do
  it 'should be equal' do
    ConditionalBlock.new(
      Variable.new("X"),
      { "a".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "a"))
        ),
        "b".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "b"))
        )
      }
    ).should == ConditionalBlock.new(
      Variable.new("X"),
      { "a".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "a"))
        ),
        "b".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "b"))
        )
      }
    )
  end

  it 'should not be equal' do
    ConditionalBlock.new(
      Variable.new("X"),
      { "a".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "a"))
        ),
        "b".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "b"))
        )
      }
    ).should != ConditionalBlock.new(
      Variable.new("Y"),
      { "a".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "a"))
        ),
        "b".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "b"))
        )
      }
    )
  end

  it 'should evaluate' do
    vtable = VariableTable.new
    block = ConditionalBlock.new(
      Variable.new("X"),
      { "a".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "a"))
        ),
        "b".to_pione =>
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("test"), "b"))
        )
      }
    )
    vtable.set(Variable.new("X"), "a".to_pione)
    block.eval(vtable).should ==
      FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("test"), "a")))
  end
end
