require_relative '../test-util'

describe 'Pione::Model::ActionBlock' do
  it 'should be equal' do
    ActionBlock.new("echo 'a'").should == ActionBlock.new("echo 'a'")
  end

  it 'should not be equal' do
    ActionBlock.new("echo 'a'").should.not == ActionBlock.new("echo 'b'")
  end

  it 'should expand variables' do
    block = ActionBlock.new("{$var1} {$var2} {$var3}")
    vtable = VariableTable.new
    vtable.set(Variable.new("var1"), PioneString.new("a").to_seq)
    vtable.set(Variable.new("var2"), PioneString.new("b").to_seq)
    vtable.set(Variable.new("var3"), PioneString.new("c").to_seq)
    block.eval(vtable).should == ActionBlock.new("a b c")
  end
end

describe 'Pione::Model::FlowBlock' do
  before do
    @rule_a = CallRule.new(RuleExpr.new(Package.new("test"), "a"))
    @rule_b = CallRule.new(RuleExpr.new(Package.new("test"), "b"))
    @rule_c = CallRule.new(RuleExpr.new(Package.new("test"), "c"))
    @var_a = Variable.new("A")
    @var_x = Variable.new("X")
    @var_y = Variable.new("Y")
    @var_z = Variable.new("Z")
  end

  it 'should be equal' do
    FlowBlock.new(@rule_a).should == FlowBlock.new(@rule_a)
  end

  it 'should not equal' do
    FlowBlock.new(@rule_a).should != FlowBlock.new(@rule_b)
  end

  it 'should get flow elements' do
    FlowBlock.new(@rule_a, @rule_b, @rule_c).elements.should == [@rule_a, @rule_b, @rule_c]
  end

  it 'should evaluate and get call-rule elements' do
    block = FlowBlock.new(
      Assignment.new(@var_x, @var_y),
      Assignment.new(@var_y, @var_z),
      ConditionalBlock.new(
        @var_a,
        { BooleanSequence.new([PioneBoolean.true]) =>
          FlowBlock.new(Assignment.new(@var_z, IntegerSequence.new([1.to_pione]))),
        }
      ),
      Assignment.new(@var_a, BooleanSequence.new([PioneBoolean.true])),
      ConditionalBlock.new(
        Message.new("==", @var_z, IntegerSequence.new([1.to_pione])),
        { BooleanSequence.new([PioneBoolean.true]) => FlowBlock.new(@rule_c) }
      ),
      @rule_a,
      @rule_b
    )
    new_block = block.eval(VariableTable.new)
    new_block.elements.should.include @rule_a
    new_block.elements.should.include @rule_b
    new_block.elements.should.include @rule_c
    new_block.elements.each{|rule| rule.should.kind_of(CallRule)}
  end
end

describe 'Pione::Model::ConditionalBlock' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
    @c = PioneString.new("c")
    @rule_a = CallRule.new(RuleExpr.new(Package.new("test"), "a"))
    @rule_b = CallRule.new(RuleExpr.new(Package.new("test"), "b"))
    @rule_c = CallRule.new(RuleExpr.new(Package.new("test"), "c"))
    @var_a = Variable.new("A")
    @var_x = Variable.new("X")
    @var_y = Variable.new("Y")
    @var_z = Variable.new("Z")
  end

  it 'should be equal' do
    ConditionalBlock.new(
      @var_x, {@a => FlowBlock.new(@rule_a), @b => FlowBlock.new(@rule_b)}
    ).should == ConditionalBlock.new(
      @var_x, {@a => FlowBlock.new(@rule_a), @b => FlowBlock.new(@rule_b)}
    )
  end

  it 'should not be equal' do
    ConditionalBlock.new(
      @var_x, {@a => FlowBlock.new(@rule_a), @b => FlowBlock.new(@rule_b)}
    ).should != ConditionalBlock.new(
      @var_y, {@a => FlowBlock.new(@rule_a), @b => FlowBlock.new(@rule_b)}
    )
  end

  it 'should evaluate' do
    block = ConditionalBlock.new(
      @var_x, {@a => FlowBlock.new(@rule_a), @b => FlowBlock.new(@rule_b)}
    )
    vtable = VariableTable.new.set(@var_x, @a)
    block.eval(vtable).should == FlowBlock.new(@rule_a)
  end
end
