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

  describe 'pione method ==' do
    it 'should true' do
      @one.call_pione_method("==", PioneFloat.new(1.0)).should.true
    end

    it 'should false' do
      @one.call_pione_method("==", @two).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("==", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      @one.call_pione_method("!=", @two).should.true
    end

    it 'should false' do
      @one.call_pione_method("!=", PioneFloat.new(1.0)).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("!=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method >' do
    it 'should true' do
      @one.call_pione_method(">", PioneFloat.new(0.0)).should.true
    end

    it 'should false' do
      @one.call_pione_method(">", PioneFloat.new(1.0)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method(">", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method >=' do
    it 'should true' do
      @one.call_pione_method(">=", PioneFloat.new(1.0)).should.true
    end

    it 'should false' do
      @one.call_pione_method(">=", @two).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method(">=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method <' do
    it 'should true' do
      @one.call_pione_method("<", @two).should.true
    end

    it 'should false' do
      @one.call_pione_method("<", PioneFloat.new(1.0)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("<", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method <=' do
    it 'should true' do
      @one.call_pione_method("<=", PioneFloat.new(1.0)).should.true
    end

    it 'should false' do
      @one.call_pione_method("<=", PioneFloat.new(0.0)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("<=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method +' do
    it 'should sum' do
      @one.call_pione_method("+", @one).should == @two
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("+", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method -' do
    it 'should get difference' do
      @two.call_pione_method("-", @one).should == @one
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("-", PioneInteger.new(1))
      end
    end
  end
end
