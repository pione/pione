require_relative '../test-util'

describe 'Pione::Component::RuleCondition' do
  before do
    @data_a = DataExpr.new("a")
    @data_b = DataExpr.new("b")
    @f_a = Feature::RequisiteExpr.new("a")
    @f_b = Feature::RequisiteExpr.new("b")
    @var_x = Variable.new("X")
    @params_a = Parameters.new(@var_x => PioneString.new("a").to_seq)
    @params_b = Parameters.new(@var_x => PioneString.new("b").to_seq)
  end

  it 'should be equal' do
    a = Component::RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    b = Component::RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    a.should == b
  end

  it 'should not be equal' do
    a = Component::RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    b = Component::RuleCondition.new([@data_b], [@data_b], params: @params_b, features: Feature.and(@f_b))
    a.should != b
  end
end

shared "rule" do
  it "should get the rule name" do
    @rule_a.name.should == "A"
    @rule_b.name.should == "B"
  end

  it "should get the package name" do
    @rule_a.package_name.should == "Test"
    @rule_b.package_name.should == "Test"
  end
end

describe 'Pione::Component::ActionRule' do
  before do
    @ts = create_tuple_space_server
    @a = PioneString.new("a")
    @b = PioneString.new("b")
    @data_a = DataExpr.new("a").to_seq
    @data_b = DataExpr.new("b").to_seq
    @f_a = Feature::RequisiteExpr.new("a")
    @f_b = Feature::RequisiteExpr.new("b")
    @var_x = Variable.new("X")
    @params_a = Parameters.new(@var_x => @a)
    @params_b = Parameters.new(@var_x => @b)
    @cond_a = Component::RuleCondition.new(
      inputs: [@data_a],
      outputs: [@data_a],
      params: @params_a,
      features: Feature.and(@f_a)
    )
    @cond_b = Component::RuleCondition.new(
      inputs: [@data_b],
      outputs: [@data_b],
      params: @params_b,
      features: Feature.and(@f_b)
    )
    @rule_a = Component::ActionRule.new("Test", "A", @cond_a, 'echo "a"')
    @rule_b = Component::ActionRule.new("Test", "B", @cond_b, 'echo "b"')
  end

  after do
    @ts.terminate
  end

  it 'should equal' do
    Component::ActionRule.new("Test", "A", @cond_a, 'echo "a"').should == @rule_a
  end

  it 'should not equal' do
    @rule_a.should != @rule_b
  end

  it 'should be action rule' do
    @rule_a.should.action
    @rule_b.should.action
  end

  it 'should be not flow rule' do
    @rule_a.should.not.flow
    @rule_b.should.not.flow
  end

  it 'should make the handler' do
    inputs = [Tuple[:data].new(name: '1.a')]
    handler = @rule_a.make_handler(@ts, inputs, Parameters.empty, [])
    handler.should.be.kind_of(RuleHandler::ActionHandler)
  end

  behaves_like "rule"
end

describe 'Pione::Component::FlowRule' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
    @data_a = DataExpr.new("a")
    @data_b = DataExpr.new("b")
    @f_a = Feature::RequisiteExpr.new("a")
    @f_b = Feature::RequisiteExpr.new("b")
    @var_x = Variable.new("X")
    @params_a = Parameters.new(@var_x => @a)
    @params_b = Parameters.new(@var_x => @b)
    @cond_a = Component::RuleCondition.new(
      inputs: [@data_a],
      outputs: [@data_a],
      params: @params_a,
      features: Feature.and(@f_a)
    )
    @cond_b = Component::RuleCondition.new(
      inputs: [@data_b],
      outputs: [@data_b],
      params: @params_b,
      features: Feature.and(@f_b)
    )
  end

  it 'should equal' do
    Component::FlowRule.new("Test", "Flow", @cond_a, 'echo "a"').should ==
      Component::FlowRule.new("Test", "Flow", @cond_a, 'echo "a"')
  end

  it 'should not equal' do
    Component::FlowRule.new("Test", "Flow1", @cond_a, 'echo "a"').should !=
      Component::FlowRule.new("Test", "Flow2",  @cond_b, 'echo "b"')
  end

  it 'should be flow rule' do
    Component::FlowRule.new("Test", "Flow", @cond_a, 'echo "a"').should.flow
  end

  it 'should be not action rule' do
    Component::FlowRule.new("Test", "Flow", @cond_a, 'echo "a"').should.not.action
  end
end
