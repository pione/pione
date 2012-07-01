require_relative '../test-util'

describe 'Model::BinaryOperator' do
  before do
    @a = Model::BinaryOperator.new("%",
                                   Model::PioneInteger.new(5),
                                   Model::PioneInteger.new(2))
    @b = Model::BinaryOperator.new("+",
                                   Model::PioneString.new("abc"),
                                   Model::PioneString.new("def"))
  end

  it 'should equal' do
    @a.should == Model::BinaryOperator.new("%",
                                           Model::PioneInteger.new(5),
                                           Model::PioneInteger.new(2))

    @b.should == Model::BinaryOperator.new("+",
                                           Model::PioneString.new("abc"),
                                           Model::PioneString.new("def"))
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    @a.eval.should == Model::PioneInteger.new(1)
    @b.eval.should == Model::PioneString.new("abcdef")
  end
end
