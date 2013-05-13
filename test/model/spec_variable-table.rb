require_relative '../test-util'

describe 'Model::VariableTable' do
  before do
    @table = VariableTable.new
    @table.set(Variable.new('A'), PioneInteger.new(1).to_seq)
    @table.set(Variable.new('B'), PioneInteger.new(2).to_seq)
    @table.set(Variable.new('C'), PioneInteger.new(3).to_seq)
  end

  it 'should get an empty table' do
    VariableTable.empty.should.empty
  end

  it 'should get a variable value' do
    @table.get(Variable.new('A')).should == PioneInteger.new(1).to_seq
    @table.get(Variable.new('B')).should == PioneInteger.new(2).to_seq
    @table.get(Variable.new('C')).should == PioneInteger.new(3).to_seq
  end

  it 'should get nil if the variable is unknown in the table' do
    @table.get(Variable.new('D')).should.nil
  end

  it 'should set a new variable' do
    @table.set(Variable.new('D'), PioneInteger.new(4))
    @table.get(Variable.new('D')).should == PioneInteger.new(4)
  end

  it 'should not raise errors by binding same value as same name variable' do
    should.not.raise(VariableBindingError) do
      @table.set(Variable.new('A'), PioneInteger.new(1).to_seq)
      @table.set(Variable.new('B'), PioneInteger.new(2).to_seq)
      @table.set(Variable.new('C'), PioneInteger.new(3).to_seq)
    end
  end

  it 'should raise an error by binding different value as same name variable' do
    should.raise(VariableBindingError) do
      @table.set(Variable.new('A'), PioneInteger.new(100))
    end
  end

  it 'should expand a string with variable name form' do
    @table.expand('{$A}').should == '1'
    @table.expand('{$B}').should == '2'
    @table.expand('{$C}').should == '3'
  end

  it 'should expand a string with variable expression form' do
    @table.expand('<? $A + 1 ?>').should == '2'
    @table.expand('<? $B + 1 ?>').should == '3'
    @table.expand('<? $C + 1 ?>').should == '4'
  end

  it 'should get keys' do
    vars = @table.variables
    vars.should.include(Variable.new("A"))
    vars.should.include(Variable.new("B"))
    vars.should.include(Variable.new("C"))
    vars.should.not.include(Variable.new("D"))
  end

  it 'should raise an error by unknown variable when expanding a string' do
    should.raise(UnboundVariableError) do
      @table.expand('{$D}')
    end
  end

  it 'should have input auto variables' do
    input_exprs = [
      DataExpr.new('*.a').to_seq,
      DataExpr.new('*.b').to_seq.set_all
    ]
    input_tuples = [
      Tuple[:data].new(name: '1.a', location: Location['test']),
      [ Tuple[:data].new(name: '1.b', location: Location['test1']),
        Tuple[:data].new(name: '2.b', location: Location['test2']),
        Tuple[:data].new(name: '3.b', location: Location['test3'])]
    ]

    @table.make_input_auto_variables(input_exprs, input_tuples)

    input = @table.get(Variable.new('I'))
    input.should.kind_of(KeyedSequence)
    input.should == @table.get(Variable.new('INPUT'))

    input1 = input.get(PioneInteger.new(1)).first
    input1.should.kind_of(DataExpr)
    input1.should == DataExpr.new("1.a")
    input1.matched_data.size.should == 2
    input1.matched_data[0].should == "1.a"
    input1.matched_data[1].should == "1"
    input1.location.should == Location["test"]

    input2 = input.get(PioneInteger.new(2))
    input2.size.should == 3
    input2[0].should.kind_of(DataExpr)
    input2[0].name.should == "1.b"
    input2[0].matched_data.size.should == 2
    input2[0].matched_data[0].should == "1.b"
    input2[0].matched_data[1].should == "1"
    input2[1].should.kind_of(DataExpr)
    input2[1].name.should == "2.b"
    input2[1].matched_data.size.should == 2
    input2[1].matched_data[0].should == "2.b"
    input2[1].matched_data[1].should == "2"
    input2[2].should.kind_of(DataExpr)
    input2[2].name.should == "3.b"
    input2[2].matched_data.size.should == 2
    input2[2].matched_data[0].should == "3.b"
    input2[2].matched_data[1].should == "3"

    @table.get(Variable.new('*')).should == StringSequence.new([PioneString.new('1')], separator: ":")
  end
end
