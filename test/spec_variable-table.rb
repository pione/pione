require 'innocent-white/test-util'

describe 'VariableTable' do
  before do
    @table = VariableTable.new
    @table.set('A', 1)
    @table.set('B', 2)
    @table.set('C', 3)
  end

  it 'should get a variable value' do
    @table.get('A').should == 1
    @table.get('B').should == 2
    @table.get('C').should == 3
  end

  it 'should get nil by unknown variable' do
    @table.get('D').should.nil
  end

  it 'should set a new variable' do
    @table.set('D', 4)
    @table.get('D').should == 4
  end

  it 'should not raise errors by binding same value as same name variable' do
    should.not.raise(VariableBindingError) do
      @table.set('A', 1)
      @table.set('B', 2)
      @table.set('C', 3)
    end
  end

  it 'should raise an error by binding different value as same name variable' do
    should.raise(VariableBindingError) do
      @table.set('A', 100)
    end
  end

  it 'should expand a string with variable name' do
    @table.expand('{$A}').should == '1'
    @table.expand('{$B}').should == '2'
    @table.expand('{$C}').should == '3'
  end

  it 'should raise an error by unknown variable when expanding a string' do
    should.raise(UnknownVariableError) do
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
    @table.get('INPUT[1]').should == '1.a'
    @table.get('INPUT[1].*').should == '1'
    @table.get('INPUT[1].MATCH[1]').should == '1'
    @table.get('INPUT[1].URI').should == 'test'
    @table.get('INPUT[2]').should == '1.b:2.b:3.b'
    @table.get('INPUT[2].*').should.nil
    @table.get('INPUT[2].MATCH[1]').should.nil
    @table.get('INPUT[2].URI').should.nil
    @table.get('INPUT[2][1]').should == '1.b'
    @table.get('INPUT[2][1].*').should == '1'
    @table.get('INPUT[2][1].MATCH[1]').should == '1'
    @table.get('INPUT[2][2]').should == '2.b'
    @table.get('INPUT[2][2].*').should == '2'
    @table.get('INPUT[2][2].MATCH[1]').should == '2'
    @table.get('INPUT[2][3]').should == '3.b'
    @table.get('INPUT[2][3].*').should == '3'
    @table.get('INPUT[2][3].MATCH[1]').should == '3'
  end
end
