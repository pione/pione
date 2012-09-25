require_relative '../test-util'

describe 'Model::Message' do
  before do
    @a = Model::Message.new("next", 1)
    @b = Model::Message.new("substring", "abcdefg", 2, 3)
  end

  it 'should equal' do
    @a.should == Model::Message.new("next", 1)
    @b.should == Model::Message.new("substring", "abcdefg", 2, 3)
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    @a.eval(VariableTable.new).should == 2.to_pione
    @b.eval(VariableTable.new).should == "cde".to_pione
  end

  it 'should get the method result from variable table' do
    vtable = VariableTable.new
    vtable.set(Variable.new("X"), @a)
    vtable.get(Variable.new("X")).should == 2.to_pione
    vtable.to_hash[Variable.new("X")].should == @a
  end

  it 'should not include variables' do
    @a.should.not.include_variable
  end

  it 'should include variables' do
    Message.new(
      "next", Variable.new("N")
    ).should.include_variable
    Message.new(
      "substring", "abcdef", Variable.new("FROM"), Variable.new("TO")
    ).should.include_variable
  end

  it 'should textize' do
    
  end
end
