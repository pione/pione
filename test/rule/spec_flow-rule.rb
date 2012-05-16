require 'innocent-white/test-util'

describe 'FlowRule' do
  before do
    create_remote_tuple_space_server
    rule_path = '/Test'
    inputs = [DataExpr.new('*.a'), DataExpr.new('{$INPUT[1].MATCH[1]}.b')]
    outputs = [DataExpr.new('{$INPUT[1].MATCH[1]}.c')]
    params = []
    features = []
    content = [Rule::FlowElement::CallRule.new(RuleExpr.new('TestAction'))]
    @rule = Rule::FlowRule.new(rule_path, inputs, outputs, params, features, content)
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

doc = Document.parse(<<-DOCUMENT)
Rule Test
  input '*.a'
  input '{$INPUT[1].*}.b'
  output '{$INPUT[1].*}.c'
Flow---
rule Shell
---End

Rule Shell
  input '*.a'
  input '{$INPUT[1].*}.b'
  output '{$INPUT[1].*}.c'
Action---
VAL1=`cat {$INPUT[1]}`;
VAL2=`cat {$INPUT[2]}`;
expr $VAL1 + $VAL2 > {$OUTPUT[1]}
---End
DOCUMENT

describe 'FlowHandler' do
  before do
    create_remote_tuple_space_server
    @rule = doc['Test']
    write(Tuple[:rule].new('Shell', doc['Shell'], :known))

    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    @tuples = [ Tuple[:data].new('test', '1.a', uri_a, Time.now),
                Tuple[:data].new('test', '1.b', uri_b, Time.now) ]
    @tuples.each {|t| write(t) }

    @handler = @rule.make_handler(tuple_space_server,
                                  @tuples,
                                  [],
                                  {:domain => 'test'})
  end

  after do
    tuple_space_server.terminate
  end

  it 'should make working directory with no process informations' do
    Dir.should.exist(@handler.working_directory)
  end

  it 'should make working directory with process informations' do
    process_name = "test-process-123"
    process_id = "xyz"
    opts = {:process_name => process_name, :process_id => process_id}
    handler = @rule.make_handler(tuple_space_server, @tuples, [], opts)
    path = handler.working_directory
    Dir.should.exist(path)
    path.should.include "#{process_name}_#{process_id}"
  end

  it "should execute a flow" do
    # execute and get result
    quiet_mode do
      thread = Thread.new { @handler.execute }
      task = read(Tuple[:task].new)
      task.rule_path.should == 'Shell'
      task.inputs.map{|d|d.name}.sort.should == ['1.a', '1.b']
      task.params.should.empty
      task.features.should.empty
      Agent[:task_worker].start(tuple_space_server)
      thread.join
      res = @handler.outputs.first
      res.name.should == '1.c'
      Resource[res.uri].read.chomp.should == "3"
      should.not.raise do
        read(Tuple[:data].new(name: '1.c', domain: @handler.domain))
      end
    end

  end
end
