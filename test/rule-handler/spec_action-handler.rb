require_relative '../test-util'

$doc = Document.parse(<<-DOCUMENT)
Rule Test
  input '*.a'
  output '{$*}.b'
Action
  nkf -w {$INPUT[1]} > {$OUTPUT[1]}
End

Rule Shell1
  input '*.a'
  input '{$*}.b'
  output '{$*}.c'
Action
  VAL1=`cat {$INPUT[1]}`;
  VAL2=`cat {$INPUT[2]}`;
  expr $VAL1 + $VAL2 > {$OUTPUT[1]}
End

Rule Shell2
  input '*.a'
  input '{$*}.b'
  output '{$*}.c'.stdout
Action
  VAL1=`cat {$INPUT[1]}`;
  VAL2=`cat {$INPUT[2]}`;
  expr $VAL1 + $VAL2
End

Rule Ruby
  input '*.a'
  input '{$*}.b'
  output '{$*}.c'.stdout
Action
#!/usr/bin/env ruby
  val1 = File.read('{$INPUT[1]}').to_i
  val2 = File.read('{$INPUT[2]}').to_i
  puts val1 + val2
End
DOCUMENT

describe 'ActionHandler' do
  before do
    create_remote_tuple_space_server
    @rule_test = $doc['&main:Test']
    @rule_sh1 = $doc['&main:Shell1']
    @rule_sh2 = $doc['&main:Shell2']
    @rule_ruby = $doc['&main:Ruby']

    @tmpdir = Dir.mktmpdir
    uri_a = "local:#{@tmpdir}/1.a"
    uri_b = "local:#{@tmpdir}/1.b"
    Resource[uri_a].create("1")
    Resource[uri_b].create("2")

    @tuple_a = Tuple[:data].new(name: '1.a', uri: uri_a, domain: "test")
    @tuple_b = Tuple[:data].new(name: '1.b', uri: uri_b, domain: "test")
    @tuples = [@tuple_a, @tuple_b]
    @tuples.each {|t| write(t) }

    @handler_sh1 = @rule_sh1.make_handler(
      tuple_space_server, @tuples, Parameters.empty, []
    )
    @handler_sh2 = @rule_sh1.make_handler(
      tuple_space_server, @tuples, Parameters.empty, []
    )
    @handler_ruby = @rule_sh1.make_handler(
      tuple_space_server, @tuples, Parameters.empty, []
    )
  end

  after do
    tuple_space_server.terminate
  end

  it 'should be made from action rule' do
    params = Parameters.empty
    handler = @rule_test.make_handler(
      tuple_space_server, [@tuple_a], params, []
    )
    handler.should.be.kind_of(RuleHandler::ActionHandler)
  end

  it 'should make working directory' do
    Dir.should.exist(@handler_sh1.working_directory)
    Dir.should.exist(@handler_sh2.working_directory)
    Dir.should.exist(@handler_ruby.working_directory)
  end

  it 'should write a shell script' do
    quiet_mode do
      process_name = "test-process-123"
      process_id = "xyz"
      opts = {:process_name => process_name, :process_id => process_id}
      handler = @rule_test.make_handler(
        tuple_space_server, [@tuple_a], Parameters.empty, []
      )
      handler.send("write_shell_script") do |path|
        File.should.exist(path)
        File.should.executable(path)
        File.read(path).should == "  nkf -w 1.a > 1.b\n"
      end
    end
  end

  it 'should call shell script' do
    quiet_mode do
      handler = @rule_test.make_handler(
        tuple_space_server, [@tuple_a], Parameters.empty, []
      )
      handler.send("write_shell_script") do |path|
        handler.send("call_shell_script", path)
        File.should.exist(File.join(handler.working_directory, "1.b"))
      end
    end
  end

  [:sh1, :sh2, :ruby].each do |sym|
    it "should execute an action: #{sym}" do
      quiet_mode do
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
end

