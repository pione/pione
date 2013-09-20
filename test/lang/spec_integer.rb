require_relative '../test-util'

describe 'Pione::Lang::PioneInteger' do
  before do
    @one = Lang::PioneInteger.new(1)
    @two = Lang::PioneInteger.new(2)
  end

  it 'should get a ruby object that has same value' do
    @one.value.should == 1
  end

  it 'should equal' do
    @one.should == Lang::PioneInteger.new(1)
  end

  it 'should not equal' do
    @one.should.not == Lang::PioneInteger.new(2)
    @one.should.not == Lang::PioneFloat.new(1.0)
  end

  test_pione_method("integer")
end
