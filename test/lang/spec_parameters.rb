require_relative '../test-util'

describe 'Pione::Lang::ParameterSetSequence' do
  before do
    @a = Lang::StringSequence.of("a")
    @b = Lang::StringSequence.of("b")
    @c = Lang::StringSequence.of("c")
    @d = Lang::StringSequence.of("d")
    @i1 = Lang::IntegerSequence.of(1)
    @i2 = Lang::IntegerSequence.of(2)
    @i3 = Lang::IntegerSequence.of(3)
    @true = Lang::BooleanSequence.of(true)
    @false = Lang::BooleanSequence.of(false)
    @var_x = Lang::Variable.new("X")
    @var_y = Lang::Variable.new("Y")
    @var_z = Lang::Variable.new("Z")
    @var_a = Lang::Variable.new("A")
    @params = Lang::ParameterSetSequence.of({@var_x => @a, @var_y => @b, @var_z => @c})
  end

  it 'should be equal' do
    @params.should == Lang::ParameterSetSequence.of({@var_x => @a, @var_y => @b, @var_z => @c})
  end

  it 'should be not equal' do
    @params.should != Lang::ParameterSetSequence.of({@var_z => @a, @var_y => @b, @var_x => @c})
  end

  it 'should expand parameter set with each modifier' do
    seq_a = Lang::StringSequence.of("a", "b", "c").set(distribution: :each)
    seq_b = Lang::IntegerSequence.of(1, 2, 3).set(distribution: :each)
    seq_c = Lang::BooleanSequence.of(true, false).set(distribution: :each)
    param_set = Lang::ParameterSet.new(table: {"X" => seq_a, "Y" => seq_b, "Z" => seq_c})
    param_set.expand.entries.tap do |list|
      list.size.should == 18
      comb = [
        [@a, @i1, @true], [@a, @i2, @true], [@a, @i3, @true],
        [@a, @i1, @false], [@a, @i2, @false], [@a, @i3, @false],
        [@b, @i1, @true], [@b, @i2, @true], [@b, @i3, @true],
        [@b, @i1, @false], [@b, @i2, @false], [@b, @i3, @false],
        [@c, @i1, @true], [@c, @i2, @true], [@c, @i3, @true],
        [@c, @i1, @false], [@c, @i2, @false], [@c, @i3, @false]
      ]
      comb.each do |elts|
        list.should.include(
          Lang::ParameterSet.new(table: {"X" => elts[0], "Y" => elts[1], "Z" => elts[2]})
        )
      end
    end
  end

  it 'should expand sequences with all distribution' do
    seq_a = Lang::StringSequence.of("a", "b", "c").set(distribution: :all)
    seq_b = Lang::IntegerSequence.of(1, 2, 3).set(distribution: :all)
    seq_c = Lang::BooleanSequence.of(true, false).set(distribution: :all)
    param_set = Lang::ParameterSet.new(table: {"X" => seq_a, "Y" => seq_b, "Z" => seq_c})
    param_set.expand.entries.tap do |list|
      list.size.should == 1
      list.should.include(Lang::ParameterSet.new(table: {"X" => seq_a, "Y" => seq_b, "Z" => seq_c}))
    end
  end

  test_pione_method("parameter-set")
end
