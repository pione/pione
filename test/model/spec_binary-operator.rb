require_relative '../test-util'

describe 'Model::BinaryOperator' do
  before do
    @a = Model::BinaryOperator.new(
      "%",
      Model::IntegerSequence.new([Model::PioneInteger.new(5)]),
      Model::IntegerSequence.new([Model::PioneInteger.new(2)])
    )
    @b = Model::BinaryOperator.new(
      "+",
      Model::StringSequence.new([Model::PioneString.new("abc")]),
      Model::StringSequence.new([Model::PioneString.new("def")])
    )
  end

  it 'should equal' do
    @a.should == Model::BinaryOperator.new(
      "%",
      Model::IntegerSequence.new([Model::PioneInteger.new(5)]),
      Model::IntegerSequence.new([Model::PioneInteger.new(2)])
    )
    @b.should == Model::BinaryOperator.new(
      "+",
      Model::StringSequence.new([Model::PioneString.new("abc")]),
      Model::StringSequence.new([Model::PioneString.new("def")])
    )
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    vtable = VariableTable.new
    @a.eval(vtable).should == Model::IntegerSequence.new([Model::PioneInteger.new(1)])
    @b.eval(vtable).should == Model::StringSequence.new([Model::PioneString.new("abcdef")])
  end
end
