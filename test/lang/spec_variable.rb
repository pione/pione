require_relative '../test-util'

describe 'Lang::Variable' do
  before do
    @a = Lang::Variable.new("a")
    @b = Lang::Variable.new("b")
  end

  it 'should equal' do
    @a.should == Lang::Variable.new("a")
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should get the value of variable' do
    env = TestUtil::Lang.env
    Lang::VariableBindingDeclaration.new(@a, Lang::IntegerSequence.of(1)).eval(env)
    @a.eval(env).should == Lang::IntegerSequence.of(1)
  end

  it 'should get the value of nested variable' do
    env = TestUtil::Lang.env
    Lang::VariableBindingDeclaration.new(@a, Lang::IntegerSequence.of(1)).eval(env)
    Lang::VariableBindingDeclaration.new(@b, @a).eval(env)
    @a.eval(env).should == Lang::IntegerSequence.of(1)
  end
end
