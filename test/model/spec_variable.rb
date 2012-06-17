require 'pione/test-util'

describe 'Model::Variable' do
  before do
    @a = Variable.new("a")
    @b = Variable.new("b")
  end

  it 'should equal' do
    @a.should == Variable.new("a")
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  describe 'pione method ==' do
    it 'should true' do
      @a.call_pione_method("==", @a).should.true
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1))
      vtable.set(@b, PioneInteger.new(1))
      BinaryOperator.new("==", @a, @b).eval(vtable).should.true
    end

    it 'should false' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1))
      vtable.set(@b, PioneInteger.new(2))
      BinaryOperator.new("==", @a, @b).eval(vtable).should.false
    end

    it 'should raise unbound variable error' do
      vtable = VariableTable.new
      vtable.set(@a)
      vtable.set(@b)
      should.raise(UnboundVariableError) do
        BinaryOperator.new("==", @a, @b).eval(vtable)
      end
    end

    it 'should raise type error' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1))
      vtable.set(@b, PioneFloat.new(1.0))
      should.raise(PioneModelTypeError) do
        BinaryOperator.new("==", @a, @b).eval(vtable)
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1))
      vtable.set(@b, PioneInteger.new(2))
      BinaryOperator.new("!=", @a, @b).eval(vtable).should.true
    end

    it 'should false' do
      @a.call_pione_method("!=", @a).should.false
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1))
      vtable.set(@b, PioneInteger.new(1))
      BinaryOperator.new("!=", @a, @b).eval(vtable).should.false
    end

    it 'should raise unbound variable error' do
      vtable = VariableTable.new
      vtable.set(@a)
      vtable.set(@b)
      should.raise(UnboundVariableError) do
        BinaryOperator.new("!=", @a, @b).eval(vtable)
      end
    end

    it 'should raise type error' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1))
      vtable.set(@b, PioneFloat.new(1.0))
      should.raise(PioneModelTypeError) do
        BinaryOperator.new("!=", @a, @b).eval(vtable)
      end
    end
  end
end
