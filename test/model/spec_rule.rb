require_relative '../test-util'

describe 'Pione::Model::RuleCondition' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
    @c = PioneString.new("c")
    @data_a = DataExpr.new("a")
    @data_b = DataExpr.new("b")
    @f_a = Feature::RequisiteExpr.new("a")
    @f_b = Feature::RequisiteExpr.new("b")
    @var_x = Variable.new("X")
    @var_y = Variable.new("Y")
    @var_z = Variable.new("Z")
    @params_a = Parameters.new(@var_x => @a)
    @params_b = Parameters.new(@var_x => @b)
  end

  it 'should be equal' do
    a = RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    b = RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    a.should == b
  end

  it 'should not be equal' do
    a = RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    b = RuleCondition.new([@data_b], [@data_b], params: @params_b, features: Feature.and(@f_b))
    a.should != b
  end
end


describe 'Pione::Model::ActionRule' do
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
    @rule_a = RuleExpr.new(PackageExpr.new("test"), 'a')
    @cond_a = RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    @cond_b = RuleCondition.new([@data_b], [@data_b], params: @params_b, features: Feature.and(@f_b))
  end

  it 'should be equal' do
    a = ActionRule.new(@rule_a, @cond_a, 'echo "a"')
    b = ActionRule.new(@rule_a, @cond_a, 'echo "a"')
    a.should == b
  end

  it 'should be not equal' do
    a = ActionRule.new(@rule_a, @cond_a, 'echo "a"')
    b = ActionRule.new(@rule_b, @cond_b, 'echo "b"')
    a.should != b
  end

  it 'should be action rule' do
    ActionRule.new(@rule_a, @cond_a, 'echo "a"').should.action
  end

  it 'should be not flow rule' do
    ActionRule.new(@rule_a, @cond_a, 'echo "a"').should.not.flow
  end

  # it 'should make an action handler' do
  #   create_tuple_space_server
  #   rule = ActionRule.new(@rule_a, @cond_a, 'echo "a"')
  #   dir = Dir.mktmpdir
  #   uri_a = "local:#{dir}/1.a"
  #   uri_b = "local:#{dir}/1.b"
  #   Resource[uri_a].create("1")
  #   inputs = [Tuple[:data].new(name: '1.a', uri: uri_a)]
  #   params = Parameters.empty
  #   handler = rule.make_handler(tuple_space_server, inputs, params, [])
  #   handler.should.be.kind_of(RuleHandler::ActionHandler)
  #   tuple_space_server.terminate
  # end
end

describe 'Pione::Model::FlowRule' do
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
    @rule_a = RuleExpr.new(PackageExpr.new("test"), 'a')
    @cond_a = RuleCondition.new([@data_a], [@data_a], params: @params_a, features: Feature.and(@f_a))
    @cond_b = RuleCondition.new([@data_b], [@data_b], params: @params_b, features: Feature.and(@f_b))
  end

  it 'should be equal' do
    a = FlowRule.new(@rule_a, @cond_a, 'echo "a"')
    b = FlowRule.new(@rule_a, @cond_a, 'echo "a"')
    a.should == b
  end

  it 'should be not equal' do
    a = FlowRule.new(@rule_a, @cond_a, 'echo "a"')
    b = FlowRule.new(@rule_b, @cond_b, 'echo "b"')
    a.should != b
  end

  it 'should be flow rule' do
    FlowRule.new(@rule_a, @cond_a, 'echo "a"').should.flow
  end

  it 'should be not action rule' do
    FlowRule.new(@rule_a, @cond_a, 'echo "a"').should.not.action
  end
end
