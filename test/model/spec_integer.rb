require_relative '../test-util'

describe 'Model::PioneInteger' do
  before do
    @one = PioneInteger.new(1)
    @two = PioneInteger.new(2)
  end

  it 'should get a ruby object that has same value' do
    @one.value.should == 1
  end

  it 'should equal' do
    @one.should == PioneInteger.new(1)
  end

  it 'should not equal' do
    @one.should.not == PioneInteger.new(2)
    @one.should.not == PioneFloat.new(1.0)
  end

  test_pione_method("integer")
end
