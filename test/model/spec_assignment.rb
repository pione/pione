require_relative '../test-util'

describe 'Model::Assignment' do
  it 'should be equal' do
    x1 = Assignment.new(Variable.new("X"), PioneString.new("a"))
    x2 = Assignment.new(Variable.new("X"), PioneString.new("a"))
    x1.should.be.equal x2
  end

  it 'should not be equal' do
    x1 = Assignment.new(Variable.new("X"), PioneString.new("a"))
    x2 = Assignment.new(Variable.new("X"), PioneString.new("b"))
    y1 = Assignment.new(Variable.new("Y"), PioneString.new("a"))
    y2 = Assignment.new(Variable.new("Y"), PioneString.new("b"))
    x1.should.not.be.equal x2
    x1.should.not.be.equal y1
    x1.should.not.be.equal y2
  end

  it 'should push variable and value into variable table' do
    Assignment.new(
      Variable.new("X"),
      PioneString.new("a")
    ).eval(VariableTable.new).should == PioneString.new("a")
  end

  it 'should evaluate the value' do
    vtable = VariableTable.new
    Assignment.new(
      Variable.new("X"),
      Message.new("as_string", PioneIntegerSequence.new([1.to_pione]))
    ).eval(vtable)
    Variable.new("X").eval(vtable).should == PioneStringSequence.new(["1".to_pione])
  end

  it 'should update variable table' do
    vtable = VariableTable.new
    Assignment.new(
      Variable.new("X"),
      "a".to_pione
    ).eval(vtable).should == "a".to_pione
    vtable.get(Variable.new("X")).should == "a".to_pione
    Assignment.new(
      Variable.new("Y"),
      Variable.new("Z")
    ).eval(vtable).should == Variable.new("Z")
    vtable.get(Variable.new("Y")).should == Variable.new("Z")
    vtable.set(Variable.new("Z"), "b".to_pione)
    vtable.get(Variable.new("Y")).should == "b".to_pione
  end
end
