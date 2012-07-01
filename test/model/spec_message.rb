require_relative '../test-util'

describe 'Model::Message' do
  before do
    @a = Model::Message.new("next", Model::PioneInteger.new(1))
    @b = Model::Message.new("substring",
                            Model::PioneString.new("abcdefg"),
                            Model::PioneInteger.new(2),
                            Model::PioneInteger.new(3))
  end

  it 'should equal' do
    @a.should == Model::Message.new("next", Model::PioneInteger.new(1))
    @b.should == Model::Message.new("substring",
                                    Model::PioneString.new("abcdefg"),
                                    Model::PioneInteger.new(2),
                                    Model::PioneInteger.new(3))
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    @a.eval.should == Model::PioneInteger.new(2)
    @b.eval.should == Model::PioneString.new("cde")
  end
end
