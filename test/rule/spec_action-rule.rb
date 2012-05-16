require 'innocent-white/test-util'

describe 'ActionRule' do
  before do
    create_remote_tuple_space_server
    rule_path = '/Test'
    inputs = [ DataExpr.new('*.a'), DataExpr.new('{$INPUT[1].MATCH[1]}.b') ]
    outputs = [ DataExpr.new('{$INPUT[1].MATCH[1]}.c') ]
    params = []
    features = []
    content = 'expr `cat {$INPUT[1]}` + `cat {$INPUT[2]}`'
    @rule = Rule::ActionRule.new(rule_path, inputs, outputs, params, features, content)
  end

  after do
    tuple_space_server.terminate
  end

  it 'should be an action' do
    @rule.should.action
  end

  it 'should not be a flow' do
    @rule.should.not.flow
  end

  it 'should make an action handler' do
    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    inputs = [Tuple[:data].new(name: '1.a', uri: uri_a),
              Tuple[:data].new(name: '1.b', uri: uri_b)]
    params = []
    handler = @rule.make_handler(tuple_space_server, inputs, params)
    handler.should.be.kind_of(Rule::ActionHandler)
  end
end

doc = Document.parse(<<-DOCUMENT)
Rule Shell1
  input '*.a'
  input '{$INPUT[1].*}.b'
  output '{$INPUT[1].*}.c'
Action---
VAL1=`cat {$INPUT[1]}`;
VAL2=`cat {$INPUT[2]}`;
expr $VAL1 + $VAL2 > {$OUTPUT[1]}
---End

Rule Shell2
  input '*.a'
  input '{$INPUT[1].*}.b'
  output '{$INPUT[1].*}.c'.stdout
Action---
VAL1=`cat {$INPUT[1]}`;
VAL2=`cat {$INPUT[2]}`;
expr $VAL1 + $VAL2
---End

Rule Ruby
  input '*.a'
  input '{$INPUT[1].*}.b'
  output '{$INPUT[1].*}.c'.stdout
Action---
#!/usr/bin/env ruby
val1 = File.read('{$INPUT[1]}').to_i
val2 = File.read('{$INPUT[2]}').to_i
puts val1 + val2
---End
DOCUMENT

describe 'ActionHandler' do
  before do
    create_remote_tuple_space_server
    @rule_sh1 = doc['Shell1']
    @rule_sh2 = doc['Shell2']
    @rule_ruby = doc['Ruby']

    dir = Dir.mktmpdir
    uri_a = "local:#{dir}/1.a"
    uri_b = "local:#{dir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    @tuples = [ Tuple[:data].new(name: '1.a', uri: uri_a),
                Tuple[:data].new(name: '1.b', uri: uri_b) ]
    @tuples.each {|t| write(t) }

    @handler_sh1 = @rule_sh1.make_handler(tuple_space_server, @tuples, [])
    @handler_sh2 = @rule_sh1.make_handler(tuple_space_server, @tuples, [])
    @handler_ruby = @rule_sh1.make_handler(tuple_space_server, @tuples, [])
  end

  after do
    tuple_space_server.terminate
  end

  it 'should make working directory with no process informations' do
    Dir.should.exist(@handler_sh1.working_directory)
    Dir.should.exist(@handler_sh2.working_directory)
    Dir.should.exist(@handler_ruby.working_directory)
  end

  it 'should make working directory with process informations' do
    process_name = "test-process-123"
    process_id = "xyz"
    opts = {:process_name => process_name, :process_id => process_id}
    handler = @rule_sh1.make_handler(tuple_space_server, @tuples, [], opts)
    path = handler.working_directory
    Dir.should.exist(path)
    path.should.include "#{process_name}_#{process_id}"
  end

  [:sh1, :sh2, :ruby].each do |sym|
    it "should execute an action: #{sym}" do
      # execute and get result
      handler = eval("@handler_#{sym}")
      outputs = handler.execute
      res = outputs.first
      res.name.should == '1.c'
      Resource[res.uri].read.chomp.should == "3"
      should.not.raise do
        read(Tuple[:data].new(name: '1.c', domain: handler.domain))
      end
    end
  end
end

