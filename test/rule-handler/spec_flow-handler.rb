require_relative '../test-util'

$document = Component::Document.parse(<<DOCUMENT)
Rule Test
  input '*.a'
  input '{$*}.b'
  output '{$*}.c'
Flow
  rule TestAction
End
DOCUMENT

describe 'FlowRule' do
  before do
    @ts = create_tuple_space_server
    @rule = $document["&main:Test"]
  end

  after do
    @ts.terminate
  end

  it 'should not be an action' do
    @rule.should.not.action
  end

  it 'should be a flow' do
    @rule.should.flow
  end

  it 'should make action handler' do
    location = Location[Temppath.create]
    location_a = location + "1.a"
    location_b = location + "1.b"
    location_a.create("1")
    location_b.create("2")

    inputs = [
      Tuple[:data].new(name: '1.a', location: location_a, time: Time.now),
      Tuple[:data].new(name: '1.b', location: location_b, time: Time.now)
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
    @ts = create_tuple_space_server
    @rule = doc['&main:Test']
    write(Tuple[:rule].new('&main:Shell', doc['&main:Shell']))

    location = Location[Temppath.create]
    location_a = location + "1.a"
    location_b = location + "1.b"
    location_a.create("1")
    location_b.create("2")

    @tuples = [
      Tuple[:data].new(domain: "test", name: '1.a', location: location_a, time: Time.now),
      Tuple[:data].new(domain: "test", name: '1.b', location: location_b, time: Time.now)
    ]
    @tuples.each {|t| write(t) }

    @handler = @rule.make_handler(@ts, @tuples, Parameters.empty, [],domain: 'test')
  end

  after do
    @ts.terminate
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
