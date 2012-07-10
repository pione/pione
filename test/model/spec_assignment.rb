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

  it 'should push its variable and value into variable table' do
    vtable = VariableTable.new
    x = Assignment.new(Variable.new("X"), PioneString.new("a"))
    x.eval(vtable)
  end
end
