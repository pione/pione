require_relative '../test-util'

describe 'Model::RuleCondition' do
  it 'should be equal' do
    a = RuleCondition.new(
      [DataExpr.new("a")],
      [DataExpr.new("a")],
      Parameters.new(Variable.new("var") => "a".to_pione),
      Feature.and(Feature::RequisiteExpr.new("a"))
    )
    b = RuleCondition.new(
      [DataExpr.new("a")],
      [DataExpr.new("a")],
      Parameters.new(Variable.new("var") => "a".to_pione),
      Feature.and(Feature::RequisiteExpr.new("a"))
    )
    a.should == b
  end

  it 'should not be equal' do
    a = RuleCondition.new(
      [DataExpr.new("a")],
      [DataExpr.new("a")],
      Parameters.new(Variable.new("var") => "a".to_pione),
      Feature.and(Feature::RequisiteExpr.new("a"))
    )
    b = RuleCondition.new(
      [DataExpr.new("b")],
      [DataExpr.new("b")],
      Parameters.new(Variable.new("var") => "b".to_pione),
      Feature.and(Feature::RequisiteExpr.new("b"))
    )
    a.should.not == b
  end
end

condition_a = RuleCondition.new(
  [DataExpr.new("a")],
  [DataExpr.new("a")],
  Parameters.new(Variable.new("var") => "a".to_pione),
  Feature.and(Feature::RequisiteExpr.new("a"))
)
condition_b = RuleCondition.new(
  [DataExpr.new("b")],
  [DataExpr.new("b")],
  Parameters.new(Variable.new("var") => "b".to_pione),
  Feature.and(Feature::RequisiteExpr.new("b"))
)

describe 'Model::ActionRule' do
  it 'should be equal' do
    a = ActionRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    b = ActionRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    a.should == b
  end

  it 'should be not equal' do
    a = ActionRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    b = ActionRule.new(
      RuleExpr.new(Package.new("test"), 'b'),
      condition_b,
      'echo "b"'
    )
    a.should.not == b
  end

  it 'should be action rule' do
    ActionRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    ).should.action
  end

  it 'should be not flow rule' do
    ActionRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    ).should.not.flow
  end

  it 'should make an action handler' do
    create_remote_tuple_space_server
    rule = ActionRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    inputs = [Tuple[:data].new(name: '1.a', uri: uri_a)]
    params = Parameters.empty
    handler = rule.make_handler(tuple_space_server, inputs, params, [])
    handler.should.be.kind_of(RuleHandler::ActionHandler)
    tuple_space_server.terminate
  end
end

describe 'Model::FlowRule' do
  it 'should be equal' do
    a = FlowRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    b = FlowRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    a.should == b
  end

  it 'should be not equal' do
    a = FlowRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    )
    b = FlowRule.new(
      RuleExpr.new(Package.new("test"), 'b'),
      condition_b,
      'echo "b"'
    )
    a.should.not == b
  end

  it 'should be flow rule' do
    FlowRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    ).should.flow
  end

  it 'should be not action rule' do
    FlowRule.new(
      RuleExpr.new(Package.new("test"), 'a'),
      condition_a,
      'echo "a"'
    ).should.not.action
  end
end
