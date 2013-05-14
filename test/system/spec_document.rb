require_relative '../test-util'

src = <<DOCUMENT
Param
  $P1 := "a"
  $P2 := "b"
  $P3 := "c"
End

param $P4 := "d"
param $P5 := "e"

$X := 1

Rule Main
  input '*.txt'
  output '*.result'
Flow
rule RuleA
rule RuleB
rule RuleC
End

Rule RuleA
  input '*.txt'
  output '{$I[1,1]}.a'
Action
command_a {$I[1]} > {$O[1]}
End

Rule RuleB
  input '*.a'
  output '{$I[1,1]}.b'
Action
command_b {$I[1]} > {$O[1]}
End

Rule RuleC
  input '*.b'
  output '{$I[1,1]}.result'
Action
command_c {$I[1]} > {$O[1]}
End
DOCUMENT

describe 'Document' do
  it 'should read a document from a string' do
    doc = Document.parse(src)
    doc.rules.size.should == 4
  end

  it 'should read a document from a file' do
    temp = Tempfile.new("spec_document")
    temp.write(src)
    path = temp.path
    temp.close(false)
    doc = Document.load(path)
    doc.rules.size.should == 4
  end

  it 'should get rules by rule path' do
    doc = Document.parse(src)
    doc["&main:Main"].should.kind_of(Model::Rule)
    doc["&main:RuleA"].should.kind_of(Model::Rule)
    doc["&main:RuleB"].should.kind_of(Model::Rule)
    doc["&main:RuleC"].should.kind_of(Model::Rule)
  end

  it 'should have document parameters' do
    doc = Document.parse(src)
    doc.params["P1"].should == PioneString.new("a").to_seq
    doc.params["P2"].should == PioneString.new("b").to_seq
    doc.params["P3"].should == PioneString.new("c").to_seq
    doc.params["P4"].should == PioneString.new("d").to_seq
    doc.params["P5"].should == PioneString.new("e").to_seq
    user_params = doc.params.data.select{|var, val| var.user_param}.map{|var, val| var.name}
    user_params.sort.should == ["P1", "P2", "P3", "P4", "P5"]
  end

  it 'should have document variable bindings' do
    doc = Document.parse(src)
    doc["&main:Main"].params["X"].should == 1.to_pione.to_seq
    doc["&main:RuleA"].params["X"].should == 1.to_pione.to_seq
    doc["&main:RuleB"].params["X"].should == 1.to_pione.to_seq
    doc["&main:RuleC"].params["X"].should == 1.to_pione.to_seq
  end

  it 'should raise variable binding error' do
    should.raise(VariableBindingError) do
      Document.parse <<-PIONE
        $X := 1
        $X := 2
      PIONE
    end
  end
end
