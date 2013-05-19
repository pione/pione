require_relative '../test-util'

$document = Component::Document.parse(<<DOCUMENT)
Rule Test
  input '*.a'
  input '{$INPUT[1].MATCH[1]}.b'
  output '{$INPUT[1].MATCH[1]}.c'
Flow
  rule TestAction
End
DOCUMENT

describe 'FlowRule' do
  before do
    create_remote_tuple_space_server
    @rule = $document["&main:Test"]
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

    inputs = [
      Tuple[:data].new(name: '1.a', uri: uri_a),
      Tuple[:data].new(name: '1.b', uri: uri_b)
    ]

    params = Parameters.empty
    handler = @rule.make_handler(tuple_space_server, inputs, params, [])
    handler.should.be.kind_of(RuleHandler::FlowHandler)
  end
end

doc = Component::Document.parse(<<-DOCUMENT)
Rule Test
  input '*.a'
  input '{$*}.b'
  output '{$*}.c'
Flow
  rule Shell
End

Rule Shell
  input '*.a'
  input '{$*}.b'
  output '{$*}.c'
Action
VAL1=`cat {$INPUT[1]}`;
VAL2=`cat {$INPUT[2]}`;
expr $VAL1 + $VAL2 > {$OUTPUT[1]}
End

Rule VariableBindingErrorTest
  input '*.a'
  output '*.b'
Flow
  rule Test
End
DOCUMENT

describe 'FlowHandler' do
  before do
    create_remote_tuple_space_server
    @rule = doc['&main:Test']
    write(Tuple[:rule].new('&main:Shell', doc['&main:Shell'], :known))

    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    @tuples = [
      Tuple[:data].new('test', '1.a', uri_a, Time.now),
      Tuple[:data].new('test', '1.b', uri_b, Time.now)
    ]
    @tuples.each {|t| write(t) }

    @handler = @rule.make_handler(
      tuple_space_server,
      @tuples,
      Parameters.empty,
      [],
      {:domain => 'test'}
    )
  end

  after do
    tuple_space_server.terminate
  end

  it "should execute a flow" do
    # execute and get result
    quiet_mode do
      thread = Thread.new { @handler.execute }
      task = read(Tuple[:task].new)
      task.rule_path.should == '&main:Shell'
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
