require_relative '../test-util'

describe 'Model::PioneBoolean' do
  before do
    @true = PioneBoolean.new(true)
    @false = PioneBoolean.new(false)
  end

  it 'should get pione true object' do
    PioneBoolean.true.should.true
    PioneBoolean.false.should.false
  end

  it 'should get a ruby object that has same value' do
    @true.to_ruby.should == true
    @false.to_ruby.should == false
  end

  it 'should equal' do
    @true.should == PioneBoolean.true
    @false.should == PioneBoolean.false
  end

  it 'should not equal' do
    @true.should.not == PioneBoolean.false
    @false.should.not == PioneBoolean.true
  end

  it 'should and' do
    PioneBoolean.and(PioneBoolean.true, PioneBoolean.true).should.true
    PioneBoolean.and(PioneBoolean.true, PioneBoolean.false).should.false
    PioneBoolean.and(PioneBoolean.false, PioneBoolean.true).should.false
    PioneBoolean.and(PioneBoolean.false, PioneBoolean.false).should.false
  end

  it 'should or' do
    PioneBoolean.or(PioneBoolean.true, PioneBoolean.true).should.true
    PioneBoolean.or(PioneBoolean.true, PioneBoolean.false).should.true
    PioneBoolean.or(PioneBoolean.false, PioneBoolean.true).should.true
    PioneBoolean.or(PioneBoolean.false, PioneBoolean.false).should.false
  end

  test_pione_method("boolean")
end
