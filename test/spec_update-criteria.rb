require_relative 'test-util'

data = DataExpr.new('*')

document = Document.parse(<<DOCUMENT)
Rule NoOutputsRule
  input '*'
Action---

--End

Rule OutputsRule
  input '*.a'
  output '*'.except('{$INPUT[1]}')
Action
echo -n "abc" > {$OUTPUT[1]}
End
DOCUMENT


time1 = Time.now
time2 = Time.now
time3 = Time.now
tuple1 = Tuple[:data].new('test', '1', nil, time1)
tuple2 = Tuple[:data].new('test', '2', nil, time2)
tuple3 = Tuple[:data].new('test', '3', nil, time2)

UC = UpdateCriteria

describe 'UpdateCriteria' do

  # no output rules
  describe 'criteria: no output rules' do
    it 'should be updatable' do
      inputs = [tuple1, tuple2]
      outputs = [tuple3]

      UC.no_output_rules?($no_outputs_rule, inputs, outputs).should.true
    end

    it 'should not be updatable' do
      input_tuples = [tuple1, tuple2]
      output_tuples = [tuple3]

      UC.no_output_rules?($outputs_rule, inputs, outputs).should.false
    end
  end

  describe 'criteria: not_exist_output' do
    before do
      inputs = [data]
      outputs = [data]
      @rule = Rule::BaseRule.new('test', inputs, outputs, [], [], nil)
    end

    it 'should be updatable' do
      inputs = [tuple1, tuple2]
      outputs = []
      UC.not_exist_output?(@rule, inputs, outputs).should.true
    end

    it 'should be not updatable' do
      inputs = []
      outputs = []
      UC.not_exist_output?(@rule)
    end

  end

end
