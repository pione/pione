require 'pione/test-helper'

describe 'Pione::TupleSpace::WorkingTuple' do
  before do
    @domain = "A"
    @digest = "_"
    @working = TupleSpace::WorkingTuple.new(@domain, @digest)
  end

  after do
    @working = nil
  end

  it 'should get identifier' do
    @working.identifier.should == :working
  end

  it 'should get domain' do
    @working.domain.should == "A"
  end

  it 'should set domain' do
    domain = "B"
    @working.domain = domain
    @working.domain.should == domain
  end

  it 'should get digest' do
    @working.digest.should == @digest
  end

  it 'should set digest' do
    digest = "1"
    @working.digest = digest
    @working.digest.should == digest
  end

  it 'should raise format error' do
    should.raise(TupleSpace::TupleFormatError) do
      TupleSpace::WorkingTuple.new(true, @digest)
    end

    should.raise(TupleSpace::TupleFormatError) do
      TupleSpace::WorkingTuple.new(@domain, true)
    end
  end

  it 'should get any tuple' do
    any = TupleSpace::WorkingTuple.any
    any.identifier.should == :working
    any.domain.should == nil
    any.digest.should == nil
  end
end
