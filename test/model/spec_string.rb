require_relative '../test-util'

describe 'Pione::Model::PioneString' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
    @vtable = VariableTable.new({
        Variable.new("var1") => @a.to_seq,
        Variable.new("var2") => @b.to_seq
      })
  end

  it 'should the value' do
    @a.value.should == "a"
  end

  it 'should equal' do
    @a.should == PioneString.new("a")
  end

  it 'should not equal' do
    @a.should != @b
  end

  it 'should include variables' do
    PioneString.new("{$var1}").should.include_variable
    PioneString.new("<? $var1 ?>").should.include_variable
  end

  it 'should not include variables' do
    PioneString.new("$var1").should.not.include_variable
    PioneString.new("<? 1 ?>").should.not.include_variable
  end

  it 'should expand variables' do
    PioneString.new("{$var1}:{$var2}").eval(@vtable).should == PioneString.new("a:b")
  end

  it 'should expand an expression' do
    PioneString.new("1 + 1 = <?1 + 1?>").eval(@vtable).should ==
      PioneString.new("1 + 1 = 2")
    PioneString.new("1 + 2 = <? 1 + 2 ?>").eval(@vtable).should ==
      PioneString.new("1 + 2 = 3")
  end

  test_pione_method("string")
end
