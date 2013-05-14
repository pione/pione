require_relative '../test-util'

describe 'Pione::Model::Assignment' do
  before do
    @var_x = Variable.new("X")
    @var_y = Variable.new("Y")
    @var_z = Variable.new("Z")
    @a = PioneString.new("a")
    @b = PioneString.new("b")
  end

  it 'should be equal' do
    x1 = Assignment.new(@var_x, @a)
    x2 = Assignment.new(@var_x, @a)
    x1.should.be.equal x2
  end

  it 'should not be equal' do
    x1 = Assignment.new(@var_x, @a)
    x2 = Assignment.new(@var_x, @b)
    y1 = Assignment.new(@var_y, @a)
    y2 = Assignment.new(@var_y, @b)
    x1.should.not.be.equal x2
    x1.should.not.be.equal y1
    x1.should.not.be.equal y2
  end

  it 'should push variable and value into variable table' do
    vtable = VariableTable.new
    Assignment.new(@var_x, @a).eval(vtable).should == @a
    vtable.get(@var_x).should == @a
  end

  it 'should evaluate the value' do
    vtable = VariableTable.new
    Assignment.new(
      @var_x,
      Message.new("as_string", IntegerSequence.new([1.to_pione]))
    ).eval(vtable)
    @var_x.eval(vtable).should == StringSequence.new([PioneString.new("1")])
  end

  it 'should update variable table' do
    vtable = VariableTable.new
    Assignment.new(@var_x, @a).eval(vtable).should == @a
    vtable.get(@var_x).should == @a
    Assignment.new(@var_y, @var_z).eval(vtable).should == @var_z
    vtable.get(@var_y).should == @var_z
    vtable.set(@var_z, @b)
    vtable.get(@var_y).should == @b
  end
end
