require_relative '../test-util'

$doc = Component::Document.parse(Location[File.dirname(__FILE__)] + "spec_action-handler.pione")

describe 'ActionHandler' do
  before do
    @ts = create_tuple_space_server

    @rule_test = $doc['&main:Test']
    @rule_sh1 = $doc['&main:Shell1']
    @rule_sh2 = $doc['&main:Shell2']
    @rule_ruby = $doc['&main:Ruby']

    location = Location[Temppath.create]
    location_a = location + "1.a"
    location_b = location + "1.b"
    location_a.create("1")
    location_b.create("2")

    @tuple_a = Tuple[:data].new(name: '1.a', location: location_a, domain: "test")
    @tuple_b = Tuple[:data].new(name: '1.b', location: location_b, domain: "test")
    @tuples = [@tuple_a, @tuple_b].tap{|t| write(t)}

    @handler_sh1 = @rule_sh1.make_handler(@ts, @tuples, Parameters.empty, [])
    @handler_sh2 = @rule_sh2.make_handler(@ts, @tuples, Parameters.empty, [])
    @handler_ruby = @rule_ruby.make_handler(@ts, @tuples, Parameters.empty, [])
  end

  after do
    @ts.terminate
  end

  it 'should be made from action rule' do
    handler = @rule_test.make_handler(@ts, [@tuple_a], Parameters.empty, [])
    handler.should.be.kind_of(RuleHandler::ActionHandler)
  end

  it 'should have working directory' do
    @handler_sh1.working_directory.should.exist
    @handler_sh2.working_directory.should.exist
    @handler_ruby.working_directory.should.exist
  end

  it 'should make different working directories' do
    @handler_sh1.make_working_directory.should != @handler_sh1.make_working_directory
  end

  it 'should write a shell script' do
    handler = @rule_test.make_handler(@ts, [@tuple_a], Parameters.empty, [])
    handler.write_shell_script do |path|
      File.should.exist(path)
      File.should.executable(path)
      File.read(path).should == "cat 1.a > 1.b\n"
    end
  end

  it 'should call shell script' do
    handler = @rule_test.make_handler(@ts, [@tuple_a], Parameters.empty, [])
    handler.write_shell_script do |path|
      handler.call_shell_script(path)
      (handler.working_directory + "1.b").should.exist
    end
  end

  [:sh1, :sh2, :ruby].each do |sym|
    it "should execute an action: #{sym}" do
      # execute and get result
      handler = eval("@handler_#{sym}")
      outputs = handler.execute
      res = outputs.first
      res.name.should == '1.c'
      res.location.read.chomp.should == "3"
      should.not.raise do
        read(Tuple[:data].new(name: '1.c', domain: handler.domain))
      end
    end
  end
end

