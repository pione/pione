require_relative '../test-util'

describe 'Model::Parameters' do
  before do
    @params_a = Parameters.new({
        Variable.new("a") => PioneString.new("A"),
        Variable.new("b") => PioneString.new("B"),
        Variable.new("c") => PioneString.new("C")
      })
  end

  it 'should be equal' do
    @params_a.should == Parameters.new({
        Variable.new("a") => PioneString.new("A"),
        Variable.new("b") => PioneString.new("B"),
        Variable.new("c") => PioneString.new("C")
      })
    set = Set.new
    set.add(@params_a)
    set.add(Parameters.new({
          Variable.new("a") => PioneString.new("A"),
          Variable.new("b") => PioneString.new("B"),
          Variable.new("c") => PioneString.new("C")
        }))
    set.size.should == 1
  end

  it 'should be not equal' do
    @params_a.should.not ==
      Parameters.new({
        Variable.new("a") => PioneString.new("X"),
        Variable.new("b") => PioneString.new("Y"),
        Variable.new("c") => PioneString.new("Z")
      })
  end

  it 'should get value' do
    params = @params_a
    params.get(Variable.new("a")).should == "A".to_pione
    params.get(Variable.new("b")).should == "B".to_pione
    params.get(Variable.new("c")).should == "C".to_pione
  end

  it 'should set a parameter' do
    params = @params_a
    new_params = params.set(Variable.new("d"), "D".to_pione)
    new_params.get(Variable.new("a")).should == "A".to_pione
    new_params.get(Variable.new("b")).should == "B".to_pione
    new_params.get(Variable.new("c")).should == "C".to_pione
    new_params.get(Variable.new("d")).should == "D".to_pione
    params.get(Variable.new("d")).should.nil
  end

  it 'should overwrite a parameter' do
    params = @params_a
    new_params = params.set(Variable.new("a"), "Z".to_pione)
    new_params.get(Variable.new("a")).should == "Z".to_pione
    new_params.get(Variable.new("b")).should == "B".to_pione
    new_params.get(Variable.new("c")).should == "C".to_pione
    params.get(Variable.new("a")).should == "A".to_pione
  end

  it 'should delete a parameter' do
    params = @params_a
    new_params = params.delete(Variable.new("a"))
    new_params.get(Variable.new("a")).should.nil
    new_params.get(Variable.new("b")).should == "B".to_pione
    new_params.get(Variable.new("c")).should == "C".to_pione
    params.get(Variable.new("a")).should == "A".to_pione
  end

  it 'should be empty' do
    Parameters.new({}).should.be.empty
  end

  it 'should not be emtpy' do
    @params_a.should.not.be.empty
  end

  it 'should expand sequence' do
    seq_a = PioneStringSequence.new([PioneString.new("X"), PioneString.new("Y"), PioneString.new("Z")])
    seq_b = PioneIntegerSequence.new([PioneInteger.new(1), PioneInteger.new(2), PioneInteger.new(3)])
    seq_c = PioneBooleanSequence.new([PioneBoolean.new(true), PioneBoolean.new(false)])
    params = Parameters.new(Variable.new("A") => seq_a, Variable.new("B") => seq_b, Variable.new("C") => seq_c)
    params.to_a.tap do |list|
      list.size.should == 18
      comb = [
        [PioneString.new("X"), PioneInteger.new(1), PioneBoolean.new(true)],
        [PioneString.new("X"), PioneInteger.new(2), PioneBoolean.new(true)],
        [PioneString.new("X"), PioneInteger.new(3), PioneBoolean.new(true)],
        [PioneString.new("X"), PioneInteger.new(1), PioneBoolean.new(false)],
        [PioneString.new("X"), PioneInteger.new(2), PioneBoolean.new(false)],
        [PioneString.new("X"), PioneInteger.new(3), PioneBoolean.new(false)],
        [PioneString.new("Y"), PioneInteger.new(1), PioneBoolean.new(true)],
        [PioneString.new("Y"), PioneInteger.new(2), PioneBoolean.new(true)],
        [PioneString.new("Y"), PioneInteger.new(3), PioneBoolean.new(true)],
        [PioneString.new("Y"), PioneInteger.new(1), PioneBoolean.new(false)],
        [PioneString.new("Y"), PioneInteger.new(2), PioneBoolean.new(false)],
        [PioneString.new("Y"), PioneInteger.new(3), PioneBoolean.new(false)],
        [PioneString.new("Z"), PioneInteger.new(1), PioneBoolean.new(true)],
        [PioneString.new("Z"), PioneInteger.new(2), PioneBoolean.new(true)],
        [PioneString.new("Z"), PioneInteger.new(3), PioneBoolean.new(true)],
        [PioneString.new("Z"), PioneInteger.new(1), PioneBoolean.new(false)],
        [PioneString.new("Z"), PioneInteger.new(2), PioneBoolean.new(false)],
        [PioneString.new("Z"), PioneInteger.new(3), PioneBoolean.new(false)]
      ]
      comb.each do |elts|
        list.should.include(
          Parameters.new(
            Variable.new("A") => elts[0].to_seq,
            Variable.new("B") => elts[1].to_seq,
            Variable.new("C") => elts[2].to_seq
          )
        )
      end
    end
  end

  describe 'pione method ==' do
    it 'should get true' do
      params_a = @params_a
      params_b = Parameters.new({
          Variable.new("a") => "A".to_pione,
          Variable.new("b") => "B".to_pione,
          Variable.new("c") => "C".to_pione
        })
      params_a.call_pione_method("==", params_b).should ==
        PioneBoolean.true
    end

    it 'should get false' do
      params_a = {"a" => "A", "b" => "B", "c" => "C"}.to_params
      params_b = {"a" => "X", "b" => "Y", "c" => "Z"}.to_params
      params_a.call_pione_method("==", params_b).should ==
        PioneBoolean.false
    end
  end

  describe 'pione method !=' do
    it 'should get true' do
      params_a = {"a" => "A", "b" => "B", "c" => "C"}.to_params
      params_b = {"a" => "X", "b" => "Y", "c" => "Z"}.to_params
      params_a.call_pione_method("!=", params_b).should ==
        PioneBoolean.true
    end

    it 'should get false' do
      params_a = {"a" => "A", "b" => "B", "c" => "C"}.to_params
      params_b = {"a" => "A", "b" => "B", "c" => "C"}.to_params
      params_a.call_pione_method("!=", params_b).should ==
        PioneBoolean.false
    end
  end

  describe 'pione method []' do
    it 'should get a value' do
      @params_a.call_pione_method("[]", "a".to_pione).should ==
        "A".to_pione
    end
  end

  describe 'pione method get' do
    it 'should get a value' do
      @params_a.call_pione_method("get", "a".to_pione).should ==
        "A".to_pione
    end
  end

  describe 'pione method set' do
    it 'should add a parameter' do
      new_params = @params_a.call_pione_method("set", "d".to_pione, "D".to_pione)
      new_params.get(Variable.new("d")).should == "D".to_pione
    end

    it 'should overwrite a parameter' do
      new_params = @params_a.call_pione_method("set", "a".to_pione, "X".to_pione)
      new_params.get(Variable.new("a")).should == "X".to_pione
    end
  end

  describe 'pione method empty?' do
    it 'should get true' do
      Parameters.new({}).call_pione_method("empty?").should ==
        PioneBoolean.true
    end
  end
end
