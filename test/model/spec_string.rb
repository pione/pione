require_relative '../test-util'

describe 'Model::PioneString' do
  before do
    @a = PioneString.new("a")
    @b = PioneString.new("b")
  end

  it 'should get a ruby object that has same value' do
    @a.value.should == "a"
  end

  it 'should equal' do
    @a.should == PioneString.new("a")
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should expand variables' do
    vtable = VariableTable.new({
        Variable.new("var1") => PioneString.new("a").to_seq,
        Variable.new("var2") => PioneString.new("b").to_seq
      })
    PioneString.new("{$var1}:{$var2}").eval(vtable).should ==
      PioneString.new("a:b")
  end

  it 'should expand an expression' do
    vtable = VariableTable.new
    PioneString.new("1 + 1 = <?1 + 1?>").eval(vtable).should ==
      PioneString.new("1 + 1 = 2")
    PioneString.new("1 + 2 = <? 1 + 2 ?>").eval(vtable).should ==
      PioneString.new("1 + 2 = 3")
  end

  test_pione_method("string")
end
