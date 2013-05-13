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

  it 'should expand sequence with each modifier' do
    seq_a = StringSequence.new([PioneString.new("X"), PioneString.new("Y"), PioneString.new("Z")]).set_each
    seq_b = IntegerSequence.new([PioneInteger.new(1), PioneInteger.new(2), PioneInteger.new(3)]).set_each
    seq_c = BooleanSequence.new([PioneBoolean.new(true), PioneBoolean.new(false)]).set_each
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

  it 'should expand sequences with all modifier' do
    seq_a = StringSequence.new([PioneString.new("X"), PioneString.new("Y"), PioneString.new("Z")]).set_all
    seq_b = IntegerSequence.new([PioneInteger.new(1), PioneInteger.new(2), PioneInteger.new(3)]).set_all
    seq_c = BooleanSequence.new([PioneBoolean.new(true), PioneBoolean.new(false)]).set_all
    params = Parameters.new(Variable.new("A") => seq_a, Variable.new("B") => seq_b, Variable.new("C") => seq_c)
    params.to_a.tap do |list|
      list.size.should == 1
      list.should.include(
        Parameters.new(
          Variable.new("A") => seq_a,
          Variable.new("B") => seq_b,
          Variable.new("C") => seq_c
        )
      )
    end
  end
end
