require 'pione/test-util'
require 'pione/rule'
require 'pione/agent/input-generator'
require 'pione/agent/task-worker'
require 'pione/agent/rule-provider'

describe 'BaseRule' do
  before do
    create_remote_tuple_space_server
    rule_path = '/Test'
    inputs = [ DataExpr.new('*.a'), DataExpr.new('{$INPUT[1].MATCH[1]}.b') ]
    outputs = [ DataExpr.new('{$INPUT[1].MATCH[1]}.c') ]
    params = []
    features = []
    content = 'expr `cat {$INPUT[1]}` + `cat {$INPUT[2]}`'
    @rule = Rule::BaseRule.new(rule_path,
                               inputs,
                               outputs,
                               params,
                               features,
                               content)
  end

  after do
    tuple_space_server.terminate
  end

  it 'should not make handler' do
    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    inputs = [Tuple[:data].new(name: '1.a', uri: uri_a),
              Tuple[:data].new(name: '1.b', uri: uri_b)]
    params = []
    should.raise(NotImplementedError) do
      @rule.make_handler(tuple_space_server, inputs, params)
    end
  end
end
