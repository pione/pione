require 'pione/test-helper'

location = Location[File.dirname(__FILE__)] + "spec_action-handler.pione"
package_id = "SpecActionHandler"
env = Lang::Environment.new.setup_new_package(package_id)
opt = {package_name: "SpecActionHandler", filename: "spec_action-handler.pione"}
context = Package::Document.load(location, opt)
context.eval(env)

describe 'Pione::RuleHandler::ActionHandler' do
  before do
    @ts = TestHelper::TupleSpace.create(self)

    location = Location[Temppath.create]
    location_a = location + "1.a"
    location_b = location + "1.b"
    location_a.create("1")
    location_b.create("2")

    param_set = Lang::ParameterSet.new(table: {
        "*" => Lang::StringSequence.of("1"),
        "INPUT" => Lang::Variable.new("I"),
        "I" => Lang::KeyedSequence.new
          .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.a"))
          .put(Lang::IntegerSequence.of(2), Lang::DataExprSequence.of("1.b")),
        "OUTPUT" => Lang::Variable.new("O"),
        "O" => Lang::KeyedSequence.new
          .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.c"))
      })

    tuple_a = Tuple[:data].new(name: '1.a', location: location_a, time: Time.now)
    tuple_b = Tuple[:data].new(name: '1.b', location: location_b, time: Time.now)
    inputs = [tuple_a, tuple_b]

    domain_id = Util::DomainID.generate(package_id, @rule_name, inputs, param_set)
    tuple_a.domain = domain_id
    tuple_b.domain = domain_id
    inputs.each {|t| write(t) }

    @handler_sh1 = RuleEngine.make(@ts, env, package_id, 'Shell1', inputs, param_set, domain_id, 'root')
    @handler_sh2 = RuleEngine.make(@ts, env, package_id, 'Shell2', inputs, param_set, domain_id, 'root')
    @handler_ruby = RuleEngine.make(@ts, env, package_id, 'Ruby', inputs, param_set, domain_id, 'root')
  end

  after do
    @ts.terminate
  end

  it 'should be action handler' do
    @handler_sh1.should.be.kind_of(RuleEngine::ActionHandler)
    @handler_sh2.should.be.kind_of(RuleEngine::ActionHandler)
    @handler_ruby.should.be.kind_of(RuleEngine::ActionHandler)
  end

  it 'should have working directory' do
    @handler_sh1.working_directory.should.exist
    @handler_sh2.working_directory.should.exist
    @handler_ruby.working_directory.should.exist
  end

  it 'should make different working directories' do
    @handler_sh1.working_directory.should != @handler_sh2.working_directory
    @handler_sh2.working_directory.should != @handler_ruby.working_directory
    @handler_ruby.working_directory.should != @handler_sh1.working_directory
  end

  it 'should write a shell script' do
    @handler_sh1.write_shell_script do |path|
      File.should.exist(path)
      File.should.executable(path)
      File.read(path).should == "VAL1=`cat 1.a`;\nVAL2=`cat 1.b`;\nexpr $VAL1 + $VAL2 > 1.c\n"
    end
  end

  it 'should call shell script' do
    @handler_sh1.setup_working_directory
    @handler_sh1.write_shell_script do |path|
      @handler_sh1.call_shell_script(path)
      (@handler_sh1.working_directory + "1.b").should.exist
    end
  end

  [:sh1, :sh2, :ruby].each do |sym|
    it "should execute an action: #{sym}" do
      # execute and get result
      handler = eval("@handler_#{sym}")
      outputs = handler.execute
      outputs[0][0].name.should == '1.c'
      outputs[0][0].location.read.chomp.should == "3"
      should.not.raise do
        read(Tuple[:data].new(name: '1.c', domain: handler.domain_id))
      end
    end
  end
end

