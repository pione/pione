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

  it 'should get the value of variable' do
    env = TestUtil::Lang.env
    Lang::VariableBindingDeclaration.new(@a, IntegerSequence.of(1)).eval(env)
    @a.eval(env).should == IntegerSequence.of(1)
  end

  it 'should get the value of nested variable' do
    env = TestUtil::Lang.env
    Lang::VariableBindingDeclaration.new(@a, IntegerSequence.of(1)).eval(env)
    Lang::VariableBindingDeclaration.new(@b, @a).eval(env)
    @a.eval(env).should == IntegerSequence.of(1)
  end
end
