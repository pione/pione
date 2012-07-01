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

  describe 'pione method ==' do
    it 'should true' do
      @true.call_pione_method("==", PioneBoolean.true).should.true
      @false.call_pione_method("==", PioneBoolean.false).should.true
    end

    it 'should false' do
      @true.call_pione_method("==", PioneBoolean.false).should.not.true
      @false.call_pione_method("==", PioneBoolean.true).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @true.call_pione_method("==", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      @true.call_pione_method("!=", PioneBoolean.false).should.true
      @false.call_pione_method("!=", PioneBoolean.true).should.true
    end

    it 'should false' do
      @true.call_pione_method("!=", PioneBoolean.true).should.not.true
      @false.call_pione_method("!=", PioneBoolean.false).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @true.call_pione_method("!=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method &&' do
    it 'should get truth' do
      @true.call_pione_method("&&", @true).should.true
      @true.call_pione_method("&&", @false).should.false
      @false.call_pione_method("&&", @true).should.false
      @false.call_pione_method("&&", @false).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @true.call_pione_method("&&", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method ||' do
    it 'should get truth' do
      @true.call_pione_method("||", @true).should.true
      @true.call_pione_method("||", @false).should.true
      @false.call_pione_method("||", @true).should.true
      @false.call_pione_method("||", @false).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @true.call_pione_method("||", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method as_string' do
    it 'should get string' do
      @true.call_pione_method("as_string").should == PioneString.new("true")
      @false.call_pione_method("as_string").should == PioneString.new("false")
    end
  end
end
