require_relative '../test-util'

describe 'Model::BinaryOperator' do
  before do
    @a = Model::BinaryOperator.new(
      "%",
      Model::PioneIntegerSequence.new([Model::PioneInteger.new(5)]),
      Model::PioneIntegerSequence.new([Model::PioneInteger.new(2)])
    )
    @b = Model::BinaryOperator.new(
      "+",
      Model::PioneStringSequence.new([Model::PioneString.new("abc")]),
      Model::PioneStringSequence.new([Model::PioneString.new("def")])
    )
  end

  it 'should equal' do
    @a.should == Model::BinaryOperator.new(
      "%",
      Model::PioneIntegerSequence.new([Model::PioneInteger.new(5)]),
      Model::PioneIntegerSequence.new([Model::PioneInteger.new(2)])
    )
    @b.should == Model::BinaryOperator.new(
      "+",
      Model::PioneStringSequence.new([Model::PioneString.new("abc")]),
      Model::PioneStringSequence.new([Model::PioneString.new("def")])
    )
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    vtable = VariableTable.new
    @a.eval(vtable).should == Model::PioneIntegerSequence.new([Model::PioneInteger.new(1)])
    @b.eval(vtable).should == Model::PioneStringSequence.new([Model::PioneString.new("abcdef")])
  end
end
