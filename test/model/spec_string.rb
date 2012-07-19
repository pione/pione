require_relative '../test-util'

describe 'Model::PioneString' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
  end

  it 'should get a ruby object that has same value' do
    @a.to_ruby.should == "a"
  end

  it 'should equal' do
    @a.should == PioneString.new("a")
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should expand variables' do
    vtable = VariableTable.new({
        Variable.new("var1") => PioneString.new("a"),
        Variable.new("var2") => PioneString.new("b")
      })
    PioneString.new("{$var1}:{$var2}").eval(vtable).should ==
      PioneString.new("a:b")
  end

  it 'should expand an expression' do
    PioneString.new("1 + 1 = <?1 + 1?>").eval.should ==
      PioneString.new("1 + 1 = 2")
  end

  describe 'pione method ==' do
    it 'should true' do
      @a.call_pione_method("==", PioneString.new("a")).should.true
    end

    it 'should false' do
      @a.call_pione_method("==", @b).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @a.call_pione_method("==", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      @a.call_pione_method("!=", @b).should.true
    end

    it 'should false' do
      @a.call_pione_method("!=", PioneString.new("a")).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @a.call_pione_method("!=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method +' do
    it 'should get appended string' do
      @a.call_pione_method("+", @b).should == PioneString.new("ab")
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @a.call_pione_method("!=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method as_string' do
    it 'should get string' do
      @a.call_pione_method("as_string").should == @a
    end
  end

  describe 'pione method length' do
    it 'should get length of string' do
      @a.call_pione_method("length").should == PioneInteger.new(1)
    end
  end

  describe 'pione method include?' do
    it 'should get truth' do
      PioneString.new("acd").call_pione_method("include?", @a).should.true
      PioneString.new("acd").call_pione_method("include?", @b).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @a.call_pione_method("include?", PioneInteger.new(1))
      end
    end
  end
end
