require_relative '../test-util'

describe 'Pione::Model::Parameters' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
    @c = PioneString.new("c")
    @d = PioneString.new("d")
    @i1 = PioneInteger.new(1)
    @i2 = PioneInteger.new(2)
    @i3 = PioneInteger.new(3)
    @true = PioneBoolean.new(true)
    @false = PioneBoolean.new(false)
    @var_x = Variable.new("X")
    @var_y = Variable.new("Y")
    @var_z = Variable.new("Z")
    @var_a = Variable.new("A")
    @params = Parameters.new({@var_x => @a, @var_y => @b, @var_z => @c})
  end

  it 'should be equal' do
    @params.should == Parameters.new({@var_x => @a, @var_y => @b, @var_z => @c})
  end

  it 'should be not equal' do
    @params.should != Parameters.new({@var_z => @a, @var_y => @b, @var_x => @c})
  end

  it 'should get the value' do
    @params.tap do |x|
      x.get(@var_x).should == @a
      x.get(@var_y).should == @b
      x.get(@var_z).should == @c
    end
  end

  it 'should set a parameter' do
    new_params = @params.set(@var_a, @d)
    new_params.get(@var_x).should == @a
    new_params.get(@var_y).should == @b
    new_params.get(@var_z).should == @c
    new_params.get(@var_a).should == @d
    @params.get(@var_a).should.nil
  end

  it 'should overwrite a parameter' do
    new_params = @params.set(@var_x, @d)
    new_params.get(@var_x).should == @d
    new_params.get(@var_y).should == @b
    new_params.get(@var_z).should == @c
    @params.get(@var_x).should == @a
  end

  it 'should delete a parameter' do
    new_params = @params.delete(@var_x)
    new_params.get(@var_x).should.nil
    new_params.get(@var_y).should == @b
    new_params.get(@var_z).should == @c
    @params.get(@var_x).should == @a
  end

  it 'should be empty' do
    Parameters.new({}).should.be.empty
  end

  it 'should not be emtpy' do
    @params.should.not.be.empty
  end

  it 'should expand sequence with each modifier' do
    seq_a = StringSequence.new([@a, @b, @c]).set_each
    seq_b = IntegerSequence.new([@i1, @i2, @i3]).set_each
    seq_c = BooleanSequence.new([@true, @false]).set_each
    params = Parameters.new(@var_x => seq_a, @var_y => seq_b, @var_z => seq_c)
    params.to_a.tap do |list|
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
          Parameters.new(@var_x => elts[0].to_seq, @var_y => elts[1].to_seq, @var_z => elts[2].to_seq)
        )
      end
    end
  end

  it 'should expand sequences with all modifier' do
    seq_a = StringSequence.new([@a, @b, @c]).set_all
    seq_b = IntegerSequence.new([@i1, @i2, @i3]).set_all
    seq_c = BooleanSequence.new([@true, @false]).set_all
    params = Parameters.new(@var_x => seq_a, @var_y => seq_b, @var_z => seq_c)
    params.to_a.tap do |list|
      list.size.should == 1
      list.should.include(Parameters.new(@var_x => seq_a, @var_y => seq_b, @var_z => seq_c))
    end
  end
end
