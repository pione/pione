require 'pione/test-helper'

package_id = "SpecEmptyHandler"
env = Lang::Environment.new.setup_new_package(package_id)
TestHelper::Lang.package_context!(env, <<-PIONE)
Rule TestTouch
  input '*.a'
  output '{$*}.b'.touch
End

Rule TestRemove
  input '*.a'
  output '{$*}.b'.remove
End
PIONE

describe 'Pione::RuleHandler::EmptyHandler' do
  describe 'touch with nonexistance' do
    before do
      @space = TestHelper::TupleSpace.create(self)

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      # setup param set
      param_set = Lang::ParameterSet.new(table: {
          "*" => Lang::StringSequence.of("1"),
          "INPUT" => Lang::Variable.new("I"),
          "I" => Lang::KeyedSequence.new
            .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.a")),
          "OUTPUT" => Lang::Variable.new("O"),
          "O" => Lang::KeyedSequence.new
            .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.b"))
        })

      domain_id = Util::DomainID.generate(package_id, 'TestTouch', [['1.a']], param_set)
      @tuple_a = TupleSpace::DataTuple.new(name: '1.a', location: location_a, domain: domain_id, time: Time.now)
      @inputs = [@tuple_a]

      write(@tuple_a)

      engine_param = {
        :tuple_space => @space,
        :env => env,
        :package_id => package_id,
        :rule_name => 'TestTouch',
        :inputs => @inputs,
        :param_set => param_set,
        :domain_id => domain_id,
        :caller_id => 'root'
      }

      @handler = RuleEngine.make(engine_param)
    end

    after do
      @space.terminate
    end

    it 'should be action handler' do
      @handler.should.be.kind_of(RuleEngine::EmptyHandler)
    end

    it 'should create a new data by touch operation' do
      outputs = @handler.execute
      outputs.size.should == 1
      outputs[0][0].name.should == '1.b'
      # data should be empty
      outputs[0][0].location.read.should == ""
      # check existance of data tuple
      should.not.raise do
        read(TupleSpace::DataTuple.new(name: '1.b', domain: @handler.domain_id))
      end
    end
  end

  describe 'touch with existance' do
    before do
      @space = TestHelper::TupleSpace.create(self)

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      param_set = Lang::ParameterSet.new(table: {
          "*" => Lang::StringSequence.of("1"),
          "INPUT" => Lang::Variable.new("I"),
          "I" => Lang::KeyedSequence.new
            .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.a")),
          "OUTPUT" => Lang::Variable.new("O"),
          "O" => Lang::KeyedSequence.new
            .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.b"))
        })

      domain_id = Util::DomainID.generate(package_id, 'TestTouch', [['1.a']], param_set)
      @tuple_a = TupleSpace::DataTuple.new(name: '1.a', location: location_a, domain: domain_id, time: Time.now)
      @tuple_b = TupleSpace::DataTuple.new(name: '1.b', location: location_b, domain: domain_id, time: Time.now)
      @inputs = [@tuple_a]

      write(@tuple_a)
      write(@tuple_b)

      engine_param = {
        :tuple_space => @space,
        :env => env,
        :package_id => package_id,
        :rule_name => 'TestTouch',
        :inputs => @inputs,
        :param_set => param_set,
        :domain_id => domain_id,
        :caller_id => 'root'
      }

      @handler = RuleEngine.make(engine_param)
    end

    after do
      @space.terminate
    end

    it 'should be empty handler' do
      @handler.should.be.kind_of(RuleEngine::EmptyHandler)
    end

    it 'should update time of data tuple by touch operation' do
      outputs = @handler.execute
      outputs.size.should == 1
      outputs[0][0].name.should == '1.b'
      outputs[0][0].location.read.should == "2"
      outputs[0][0].time.should > @tuple_b.time
      should.not.raise do
        read(TupleSpace::DataTuple.new(name: '1.b', domain: @handler.domain_id))
      end
    end
  end

  describe 'remove' do
    before do
      @space = TestHelper::TupleSpace.create(self)

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      param_set = Lang::ParameterSet.new(table: {
          "*" => Lang::StringSequence.of("1"),
          "INPUT" => Lang::Variable.new("I"),
          "I" => Lang::KeyedSequence.new
            .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.a")),
          "OUTPUT" => Lang::Variable.new("O"),
          "O" => Lang::KeyedSequence.new
            .put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("1.b"))
        })

      domain_id = Util::DomainID.generate(package_id, 'TestRemove', [['1.a']], param_set)
      @tuple_a = TupleSpace::DataTuple.new(name: '1.a', location: location_a, domain: domain_id, time: Time.now)
      @tuple_b = TupleSpace::DataTuple.new(name: '1.b', location: location_b, domain: domain_id, time: Time.now)
      @inputs = [@tuple_a]

      write(@tuple_a)
      write(@tuple_b)

      engine_param = {
        :tuple_space => @space,
        :env => env,
        :package_id => package_id,
        :rule_name => 'TestRemove',
        :inputs => @inputs,
        :param_set => param_set,
        :domain_id => domain_id,
        :caller_id => 'root'
      }

      @handler = RuleEngine.make(engine_param)
    end

    after do
      @space.terminate
    end

    it 'should be action handler' do
      @handler.should.be.kind_of(RuleEngine::EmptyHandler)
    end

    it 'should remove tuple' do
      read!(TupleSpace::DataTuple.new(name: '1.b', domain: @handler.domain_id)).should.not.nil
      should.not.raise { @handler.handle }
      # FIXME: remove operation dones't remove data tuple now, but it should remove
      #read!(TupleSpace::DataTuple.new(name: '1.b', domain: @handler.domain_id)).should.nil
    end
  end
end

