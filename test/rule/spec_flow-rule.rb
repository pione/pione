require 'innocent-white/test-util'

describe 'FlowRule' do
  before do
    create_remote_tuple_space_server
    rule_path = '/Test'
    inputs = [DataExpr.new('*.a'), DataExpr.new('{$INPUT[1].MATCH[1]}.b')]
    outputs = [DataExpr.new('{$INPUT[1].MATCH[1]}.c')]
    params = []
    content = [Rule::FlowElement::CallRule.new(RuleExpr.new('TestAction'))]
    @rule = Rule::FlowRule.new(rule_path, inputs, outputs, params, content)
  end

  after do
    tuple_space_server.terminate
  end

  it 'should not be an action' do
    @rule.should.not.action
  end

  it 'should be a flow' do
    @rule.should.flow
  end

  it 'should make action handler' do
    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    inputs = [Tuple[:data].new(name: '1.a', uri: uri_a),
              Tuple[:data].new(name: '1.b', uri: uri_b)]
    params = []
    handler = @rule.make_handler(tuple_space_server, inputs, params)
    handler.should.be.kind_of(Rule::FlowHandler)
  end
end
