require_relative '../test-util'

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
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      vtable.set(@b, PioneInteger.new(1).to_seq)
      BinaryOperator.new("==", @a, @b).eval(vtable).should == PioneBoolean.new(true).to_seq
    end

    it 'should false' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      vtable.set(@b, PioneInteger.new(2).to_seq)
      BinaryOperator.new("==", @a, @b).eval(vtable).should == PioneBoolean.new(false).to_seq
    end

    it 'should raise unbound variable error' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      should.raise(UnboundVariableError) do
        BinaryOperator.new("==", @a, @b).eval(vtable)
      end
    end

    it 'should raise type error' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      vtable.set(@b, PioneFloat.new(1.0).to_seq)
      should.raise(MethodNotFound) do
        BinaryOperator.new("==", @a, @b).eval(vtable)
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      vtable.set(@b, PioneInteger.new(2).to_seq)
      BinaryOperator.new("!=", @a, @b).eval(vtable).should == PioneBoolean.new(true).to_seq
    end

    it 'should false' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      vtable.set(@b, PioneInteger.new(1).to_seq)
      BinaryOperator.new("!=", @a, @b).eval(vtable).should == PioneBoolean.new(false).to_seq
    end

    it 'should raise unbound variable error' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      should.raise(UnboundVariableError) do
        BinaryOperator.new("!=", @a, @b).eval(vtable)
      end
    end

    it 'should raise type error' do
      vtable = VariableTable.new
      vtable.set(@a, PioneInteger.new(1).to_seq)
      vtable.set(@b, PioneFloat.new(1.0).to_seq)
      should.raise(MethodNotFound) do
        BinaryOperator.new("!=", @a, @b).eval(vtable)
      end
    end
  end
end
