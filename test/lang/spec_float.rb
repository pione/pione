require 'pione/test-helper'

describe 'Pione::Lang::PioneFloat' do
  before do
    @one = Lang::PioneFloat.new(1.0)
    @two = Lang::PioneFloat.new(2.0)
  end

  it 'should get a ruby object that has same value' do
    @one.value.should == 1.0
  end

  it 'should equal' do
    @one.should == Lang::PioneFloat.new(1.0)
  end

  it 'should not equal' do
    @one.should.not == Lang::PioneFloat.new(2.0)
    @one.should.not == Lang::PioneInteger.new(1)
  end

  TestHelper::Lang.test_pione_method(__FILE__)
end
