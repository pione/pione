require 'pione/test-helper'

describe 'Pione::Lang::PioneInteger' do
  before do
    @zero = Lang::PioneInteger.new(0)
    @one = Lang::PioneInteger.new(1)
    @two = Lang::PioneInteger.new(2)
  end

  it 'should get a ruby object that has same value' do
    @zero.value.should == 0
    @one.value.should == 1
    @two.value.should == 2
  end

  it 'should equal' do
    @zero.should == Lang::PioneInteger.new(0)
    @one.should == Lang::PioneInteger.new(1)
    @two.should == Lang::PioneInteger.new(2)
  end

  it 'should not equal' do
    @zero.should.not == Lang::PioneBoolean.new(false)
    @one.should.not == Lang::PioneInteger.new(2)
    @one.should.not == Lang::PioneFloat.new(1.0)
  end

  TestHelper::Lang.test_pione_method(__FILE__)
end
