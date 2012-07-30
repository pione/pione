require_relative 'test-util'

data = DataExpr.new('*')

document = Document.parse(<<DOCUMENT)
Rule NoOutputsRule
  input '*'
Action---

--End

Rule OutputsRule
  input '*.a'
  output '*.b'
Action
cat {$INPUT[1]} > {$OUTPUT[1]}
End
DOCUMENT
$no_outputs_rule = document["&main:NoOutputsRule"]
$outputs_rule = document["&main:OutputsRule"]


time1 = Time.now
time2 = Time.now
time3 = Time.now
tuple1 = Tuple[:data].new('test', '1.a', nil, time1)
tuple2 = Tuple[:data].new('test', '2.a', nil, time2)
tuple3 = Tuple[:data].new('test', '3.b', nil, time2)

UC = UpdateCriteria

describe 'UpdateCriteria' do

  # no output rules
  describe 'criteria: no output rules' do
    it 'should be updatable' do
      inputs = [tuple1, tuple2]
      outputs = [tuple3]

      UC.no_output_rules?(
        $no_outputs_rule,
        inputs,
        outputs,
        VariableTable.new
      ).should.true
    end

    it 'should not be updatable' do
      inputs = [tuple1, tuple2]
      outputs = [tuple3]
      UC.no_output_rules?(
        $outputs_rule,
        inputs,
        outputs,
        VariableTable.new
      ).should.false
    end
  end

  describe 'criteria: not_exist_output' do
    it 'should be updatable' do
      inputs = [tuple1, tuple2]
      outputs = []
      UC.not_exist_output?(
        $outputs_rule,
        inputs,
        outputs,
        VariableTable.new
      ).should.true
    end

    it 'should be not updatable' do
      inputs = [tuple1]
      outputs = [tuple3]
      UC.not_exist_output?(
        $outputs_rule,
        inputs,
        outputs,
        VariableTable.new
      ).should.false
    end
  end
end
