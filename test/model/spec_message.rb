require_relative '../test-util'

describe 'Model::Message' do
  before do
    @a = Model::Message.new("next", PioneInteger.new(1).to_seq)
    @b = Model::Message.new("substring", PioneString.new("abcdefg").to_seq, PioneInteger.new(2).to_seq, PioneInteger.new(3).to_seq)
  end

  it 'should equal' do
    @a.should == Model::Message.new("next", PioneInteger.new(1).to_seq)
    @b.should == Model::Message.new("substring", PioneString.new("abcdefg").to_seq, PioneInteger.new(2).to_seq, PioneInteger.new(3).to_seq)
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    @a.eval(VariableTable.new).should == PioneInteger.new(2).to_seq
    @b.eval(VariableTable.new).should == PioneString.new("bcd").to_seq
  end

  it 'should get the method result from variable table' do
    vtable = VariableTable.new
    vtable.set(Variable.new("X"), @a)
    vtable.get(Variable.new("X")).should == PioneInteger.new(2).to_seq
    vtable.to_hash[Variable.new("X")].should == @a
  end

  it 'should not include variables' do
    @a.should.not.include_variable
  end

  it 'should include variables' do
    Message.new("next", Variable.new("N")).should.include_variable
    Message.new(
      "substring", PioneString.new("abcdef"), Variable.new("FROM"), Variable.new("TO")
    ).should.include_variable
  end
end
