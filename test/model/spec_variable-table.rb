require_relative '../test-util'

describe 'Model::VariableTable' do
  before do
    @table = VariableTable.new
    @table.set(Variable.new('A'), PioneInteger.new(1))
    @table.set(Variable.new('B'), PioneInteger.new(2))
    @table.set(Variable.new('C'), PioneInteger.new(3))
  end

  it 'should get a variable value' do
    @table.get(Variable.new('A')).should == PioneInteger.new(1)
    @table.get(Variable.new('B')).should == PioneInteger.new(2)
    @table.get(Variable.new('C')).should == PioneInteger.new(3)
  end

  it 'should get nil by unknown variable' do
    @table.get(Variable.new('D')).should.nil
  end

  it 'should set a new variable' do
    @table.set(Variable.new('D'), PioneInteger.new(4))
    @table.get(Variable.new('D')).should == PioneInteger.new(4)
  end

  it 'should not raise errors by binding same value as same name variable' do
    should.not.raise(VariableBindingError) do
      @table.set(Variable.new('A'), PioneInteger.new(1))
      @table.set(Variable.new('B'), PioneInteger.new(2))
      @table.set(Variable.new('C'), PioneInteger.new(3))
    end
  end

  it 'should raise an error by binding different value as same name variable' do
    should.raise(VariableBindingError) do
      @table.set(Variable.new('A'), PioneInteger.new(100))
    end
  end

  it 'should expand a string with variable name' do
    @table.expand('{$A}').should == '1'
    @table.expand('{$B}').should == '2'
    @table.expand('{$C}').should == '3'
  end

  it 'should raise an error by unknown variable when expanding a string' do
    should.raise(UnboundVariableError) do
      @table.expand('{$D}')
    end
  end

  it 'should have input auto variables' do
    input_exprs = [ DataExpr.new('*.a'),
                    DataExpr.new('*.b').all ]
    input_tuples = [Tuple[:data].new(name: '1.a', uri: 'test'),
                    [Tuple[:data].new(name: '1.b', uri: 'test1'),
                     Tuple[:data].new(name: '2.b', uri: 'test2'),
                     Tuple[:data].new(name: '3.b', uri: 'test3')]]
    @table.make_input_auto_variables(input_exprs, input_tuples)
    @table.get(Variable.new('INPUT[1]')).should ==
      PioneString.new('1.a')
    @table.get(Variable.new('INPUT[1].*')).should ==
      PioneString.new('1')
    @table.get(Variable.new('INPUT[1].MATCH[1]')).should ==
      PioneString.new('1')
    @table.get(Variable.new('INPUT[1].URI')).should ==
      PioneString.new('test')
    @table.get(Variable.new('INPUT[2]')).should ==
      PioneString.new('1.b:2.b:3.b')
    @table.get(Variable.new('INPUT[2].*')).should.nil
    @table.get(Variable.new('INPUT[2].MATCH[1]')).should.nil
    @table.get(Variable.new('INPUT[2].URI')).should.nil
    @table.get(Variable.new('INPUT[2][1]')).should ==
      PioneString.new('1.b')
    @table.get(Variable.new('INPUT[2][1].*')).should ==
      PioneString.new('1')
    @table.get(Variable.new('INPUT[2][1].MATCH[1]')).should ==
      PioneString.new('1')
    @table.get(Variable.new('INPUT[2][2]')).should ==
      PioneString.new('2.b')
    @table.get(Variable.new('INPUT[2][2].*')).should ==
      PioneString.new('2')
    @table.get(Variable.new('INPUT[2][2].MATCH[1]')).should ==
      PioneString.new('2')
    @table.get(Variable.new('INPUT[2][3]')).should ==
      PioneString.new('3.b')
    @table.get(Variable.new('INPUT[2][3].*')).should ==
      PioneString.new('3')
    @table.get(Variable.new('INPUT[2][3].MATCH[1]')).should ==
      PioneString.new('3')
  end
end
