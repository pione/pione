require_relative 'test-util'

src = <<DOCUMENT
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
end
