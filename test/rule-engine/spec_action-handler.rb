require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data" + "action-handler"
  this::BASIC_ACTION = this::DIR + "BasicAction.pione"
  this::USE_PACKAGE_SCRIPT = this::DIR + "UsePackageScript.pione"

  describe 'Pione::RuleHandler::ActionHandler' do
    describe "basic actions" do
      before do
        env = Lang::Environment.new.setup_new_package("BasicAction")
        package_id = "BasicAction"
        Package::Document.load(env, this::BASIC_ACTION, package_id, nil, nil, "BasicAction.pione")

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

        tuple_a = TupleSpace::DataTuple.new(name: '1.a', location: location_a, time: Time.now)
        tuple_b = TupleSpace::DataTuple.new(name: '1.b', location: location_b, time: Time.now)
        inputs = [tuple_a, tuple_b]

        domain_id = Util::DomainID.generate(package_id, @rule_name, inputs, param_set)
        tuple_a.domain = domain_id
        tuple_b.domain = domain_id
        inputs.each {|t| write(t) }

        engine_param = {
          :tuple_space => @ts,
          :env => env,
          :package_id => package_id,
          :inputs => inputs,
          :param_set => param_set,
          :domain_id => domain_id,
          :caller_id => 'root'
        }

        @handler_sh1 = RuleEngine.make(engine_param.merge(rule_name: 'Shell1'))
        @handler_sh2 = RuleEngine.make(engine_param.merge(rule_name: 'Shell2'))
        @handler_ruby = RuleEngine.make(engine_param.merge(rule_name: 'Ruby'))
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
        @handler_sh1.working_directory.location.should.exist
        @handler_sh2.working_directory.location.should.exist
        @handler_ruby.working_directory.location.should.exist
      end

      it 'should make different working directories' do
        @handler_sh1.working_directory.location.should != @handler_sh2.working_directory.location
        @handler_sh2.working_directory.location.should != @handler_ruby.working_directory.location
        @handler_ruby.working_directory.location.should != @handler_sh1.working_directory.location
      end

      it 'should write a shell script' do
        @handler_sh1.shell_script.write
        location = @handler_sh1.shell_script.location
        location.should.exist
        location.path.should.executable
        location.read.should == "VAL1=`cat 1.a`;\nVAL2=`cat 1.b`;\nexpr $VAL1 + $VAL2 > 1.c\n"
      end

      [:sh1, :sh2, :ruby].each do |sym|
        it "should execute an action: #{sym}" do
          # execute and get result
          handler = eval("@handler_#{sym}")
          outputs = handler.execute
          outputs[0][0].name.should == '1.c'
          outputs[0][0].location.read.chomp.should == "3"
          should.not.raise do
            read(TupleSpace::DataTuple.new(name: '1.c', domain: handler.domain_id))
          end
        end
      end
    end

    describe "use package script" do
      before do
        env = Lang::Environment.new.setup_new_package("UsePackageScript")
        package_id = "UsePackageScript"
        Package::Document.load(env, this::USE_PACKAGE_SCRIPT, package_id, nil, nil, "UsePackageScript.pione")

        @ts = TestHelper::TupleSpace.create(self)

        location = Location[Temppath.create]
        location_a = location + "1.a"
        location_a.create("1")

        param_set = Lang::ParameterSet.new(table: {
            "*" => Lang::StringSequence.of("1"),
            "INPUT" => Lang::Variable.new("I"),
            "I" => Lang::KeyedSequence.new
              .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.a")),
            "OUTPUT" => Lang::Variable.new("O"),
            "O" => Lang::KeyedSequence.new
              .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.b"))
          })

        tuple_a = TupleSpace::DataTuple.new(name: '1.a', location: location_a, time: Time.now)
        inputs = [tuple_a]

        sh = @ts.base_location + "package" + "bin" + "test.sh"
        sh.write("echo abc > 1.b")
        sh.path.chmod(0700)

        domain_id = Util::DomainID.generate(package_id, @rule_name, inputs, param_set)
        tuple_a.domain = domain_id
        inputs.each {|t| write(t) }

        engine_param = {
          :tuple_space => @ts,
          :env => env,
          :package_id => package_id,
          :inputs => inputs,
          :param_set => param_set,
          :domain_id => domain_id,
          :caller_id => 'root'
        }

        @handler1 = RuleEngine.make(engine_param.merge(rule_name: 'R1'))
        @handler2 = RuleEngine.make(engine_param.merge(rule_name: 'R2'))
      end

      after do
        @ts.terminate
      end

      it "should call package script" do
        outputs = @handler1.execute
        outputs[0][0].name.should == '1.b'
        outputs[0][0].location.read.chomp.should == "abc"
        should.not.raise do
          read(TupleSpace::DataTuple.new(name: '1.b', domain: @handler1.domain_id))
        end
      end

      it "should raise action error because the script not found" do
        should.raise(RuleEngine::ActionError) do
          outputs = @handler2.execute
        end
      end
    end
  end
end
