require_relative '../test-util'

describe 'Model::PioneInteger' do
  before do
    @one = PioneInteger.new(1)
    @two = PioneInteger.new(2)
  end

  it 'should get a ruby object that has same value' do
    @one.to_ruby.should == 1
  end

  it 'should equal' do
    @one.should == PioneInteger.new(1)
  end

  it 'should not equal' do
    @one.should.not == PioneInteger.new(2)
    @one.should.not == PioneFloat.new(1.0)
  end

  describe 'pione method ==' do
    it 'should true' do
      @one.call_pione_method("==", PioneInteger.new(1)).should.true
    end

    it 'should false' do
      @one.call_pione_method("==", PioneInteger.new(2)).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("==", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      @one.call_pione_method("!=", PioneInteger.new(2)).should.true
    end

    it 'should false' do
      @one.call_pione_method("!=", PioneInteger.new(1)).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("!=", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method >' do
    it 'should true' do
      @one.call_pione_method(">", PioneInteger.new(0)).should.true
    end

    it 'should false' do
      @one.call_pione_method(">", PioneInteger.new(1)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method(">", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method >=' do
    it 'should true' do
      @one.call_pione_method(">=", PioneInteger.new(1)).should.true
    end

    it 'should false' do
      @one.call_pione_method(">=", PioneInteger.new(2)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method(">=", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method <' do
    it 'should true' do
      @one.call_pione_method("<", PioneInteger.new(2)).should.true
    end

    it 'should false' do
      @one.call_pione_method("<", PioneInteger.new(1)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("<", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method <=' do
    it 'should true' do
      @one.call_pione_method("<=", PioneInteger.new(1)).should.true
    end

    it 'should false' do
      @one.call_pione_method("<=", PioneInteger.new(0)).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("<=", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method +' do
    it 'should sum' do
      @one.call_pione_method("+", @one).should == @two
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("+", PioneFloat.new(1.0))
      end
    end
  end

  describe 'pione method -' do
    it 'should get difference' do
      @two.call_pione_method("-", @one).should == @one
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @one.call_pione_method("-", PioneFloat.new(1.0))
      end
    end
  end
end
