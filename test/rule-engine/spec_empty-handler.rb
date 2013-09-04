require_relative '../test-util'

package_id = "SpecEmptyHandler"
env = Lang::Environment.new.setup_new_package(package_id)
TestUtil::Lang.package_context!(env, <<-PIONE)
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
      @space = create_tuple_space_server

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      # setup param set
      param_set = ParameterSet.new(table: {
          "*" => StringSequence.of("1"),
          "INPUT" => Variable.new("I"),
          "I" => KeyedSequence.new
            .put(IntegerSequence.of(1), DataExprSequence.of("1.a")),
          "OUTPUT" => Variable.new("O"),
          "O" => KeyedSequence.new
            .put(IntegerSequence.of(1), DataExprSequence.of("1.b"))
        })

      domain_id = Util::DomainID.generate(package_id, 'TestTouch', [['1.a']], param_set)
      @tuple_a = Tuple[:data].new(name: '1.a', location: location_a, domain: domain_id, time: Time.now)
      @inputs = [@tuple_a]

      write(@tuple_a)

      @handler = RuleEngine.make(@space, env, package_id, 'TestTouch', @inputs, param_set, domain_id, 'root')
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
        read(Tuple[:data].new(name: '1.b', domain: @handler.domain_id))
      end
    end
  end

  describe 'touch with existance' do
    before do
      @space = create_tuple_space_server

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      param_set = ParameterSet.new(table: {
          "*" => StringSequence.of("1"),
          "INPUT" => Variable.new("I"),
          "I" => KeyedSequence.new
            .put(IntegerSequence.of(1), DataExprSequence.of("1.a")),
          "OUTPUT" => Variable.new("O"),
          "O" => KeyedSequence.new
            .put(IntegerSequence.of(1), DataExprSequence.of("1.b"))
        })

      domain_id = Util::DomainID.generate(package_id, 'TestTouch', [['1.a']], param_set)
      @tuple_a = Tuple[:data].new(name: '1.a', location: location_a, domain: domain_id, time: Time.now)
      @tuple_b = Tuple[:data].new(name: '1.b', location: location_b, domain: domain_id, time: Time.now)
      @inputs = [@tuple_a]

      write(@tuple_a)
      write(@tuple_b)

      @handler = RuleEngine.make(@space, env, package_id, 'TestTouch', @inputs, param_set, domain_id, 'root')
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
        read(Tuple[:data].new(name: '1.b', domain: @handler.domain_id))
      end
    end
  end

  describe 'remove' do
    before do
      @space = create_tuple_space_server

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      param_set = ParameterSet.new(table: {
          "*" => StringSequence.of("1"),
          "INPUT" => Variable.new("I"),
          "I" => KeyedSequence.new
            .put(IntegerSequence.of(1), DataExprSequence.of("1.a")),
          "OUTPUT" => Variable.new("O"),
          "O" => KeyedSequence.new
            .put(IntegerSequence.of(1), DataExprSequence.of("1.b"))
        })

      domain_id = Util::DomainID.generate(package_id, 'TestRemove', [['1.a']], param_set)
      @tuple_a = Tuple[:data].new(name: '1.a', location: location_a, domain: domain_id, time: Time.now)
      @tuple_b = Tuple[:data].new(name: '1.b', location: location_b, domain: domain_id, time: Time.now)
      @inputs = [@tuple_a]

      write(@tuple_a)
      write(@tuple_b)

      @handler = RuleEngine.make(@space, env, package_id, 'TestRemove', @inputs, param_set, domain_id, 'root')
    end

    after do
      @space.terminate
    end

    it 'should be action handler' do
      @handler.should.be.kind_of(RuleEngine::EmptyHandler)
    end

    it 'should remove tuple' do
      read!(Tuple[:data].new(name: '1.b', domain: @handler.domain_id)).should.not.nil
      should.not.raise { @handler.handle }
      # FIXME: remove operation dones't remove data tuple now, but it should remove
      #read!(Tuple[:data].new(name: '1.b', domain: @handler.domain_id)).should.nil
    end
  end
end

