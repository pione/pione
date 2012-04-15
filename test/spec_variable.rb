require 'innocent-white/test-util'

describe 'Variable' do
  it 'should get a variable name' do
    Variable.new('abc').name.should == 'abc'
  end

  it 'should be equal with same name variable' do
    Variable.new('abc').should == Variable.new('abc')
  end
end

describe 'VariableTable' do
  before do
    @vtable = VariableTable.new
    @vtable.set('a', 1)
    @vtable.set('b', 2)
    @vtable.set('c', 3)
  end

  it 'should get a variable value' do
    @vtable.get('a').should == 1
    @vtable.get(Variable.new('b')).should == 2
  end

  it 'should get nil by unknown variable' do
    @vtable.get('d').should.nil
  end

  it 'should set a new variable' do
    @vtable.set('d', 4)
    @vtable.get('d').should == 4
  end

  it 'should not raise errors by binding same value as same name variable' do
    should.not.raise(VariableBindingError) do
      @vtable.set('a', 1)
      @vtable.set('b', 2)
      @vtable.set('c', 3)
    end
  end

  it 'should raise an error by binding different value as same name variable' do
    should.raise(VariableBindingError) do
      @vtable.set('a', 100)
    end
  end

  it 'should expand a string with variable name' do
    @vtable.expand_string(' {$a} ').should == ' 1 '
  end

  it 'should raise an error by unknown variable when expanding a string' do
    should.raise(UnknownVariableError) do
      @vtable.expand_string(' {$d} ')
    end
  end

end
