require 'innocent-white/test-util'

data = DataExpr.new('*')

time1 = Time.now
time2 = Time.now
time3 = Time.now
tuple1 = Tuple[:data].new('test', '1', nil, time1)
tuple2 = Tuple[:data].new('test', '2', nil, time2)
tuple3 = Tuple[:data].new('test', '3', nil, time2)

UC = UpdateCriteria

describe 'UpdateCriteria' do
  describe 'criteria: no output rules' do
    it 'should be updatable' do
      inputs = [data]
      outputs = []
      rule = Rule::BaseRule.new('test', inputs, outputs, [], [], nil)

      input_tuples = [tuple1, tuple2]
      output_tuples = [tuple3]

      UC.no_output_rules?(rule, input_tuples, output_tuples).should.true
    end

    it 'should not be updatable' do
      inputs = [data]
      outputs = [data]
      rule = Rule::BaseRule.new('test', inputs, outputs, [], [], nil)

      input_tuples = [tuple1, tuple2]
      output_tuples = [tuple3]

      UC.no_output_rules?(rule, input_tuples, output_tuples).should.false
    end
  end

  describe 'criteria: not_exist_output' do
    it 'should be updatable' do
      inputs = [tuple1, tuple2]
      outputs = [tuple3]
      UC.no_output_rules?(@rule, inputs, outputs).should.true
    end

    it 'should be not updatable' do
      
    end

  end

end
