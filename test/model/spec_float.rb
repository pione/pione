require_relative '../test-util'

describe 'Model::PioneFloat' do
  before do
    @one = PioneFloat.new(1.0)
    @two = PioneFloat.new(2.0)
  end

  it 'should get a ruby object that has same value' do
    @one.to_ruby.should == 1.0
  end

  it 'should equal' do
    @one.should == PioneFloat.new(1.0)
  end

  it 'should not equal' do
    @one.should.not == PioneFloat.new(2.0)
    @one.should.not == PioneInteger.new(1)
  end

  test_pione_method("float")
end
