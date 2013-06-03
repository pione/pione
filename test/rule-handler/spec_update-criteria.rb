require_relative '../test-util'

path = Pathname.new(File.join(File.dirname(__FILE__), "spec_update-criteria.pione"))
document = Component::Document.load(path.read)

time = 10.times.map {sleep 0.001; Time.now}
tuple = {}
['a', 'b', 'c'].map do |ext|
  10.times do |i|
    name = 't%d.%s' % [i, ext]
    tuple[name] = Tuple[:data].new('test', name, nil, time[i])
  end
end

UC = Pione::RuleHandler::UpdateCriteria

#
# test cases
#
yamlname = 'spec_update-criteria.yml'
ymlpath = File.join(File.dirname(__FILE__), yamlname)
testcases = YAML.load_file(ymlpath)

describe 'RuleHandler::UpdateCriteria' do
  testcases.each do |rule_name, cases|
    rule = document.find(rule_name)
    describe rule_name do
      cases.each do |case_name, testcase|
        describe case_name do
          inputs = (testcase["inputs"] || []).map do |input|
            input.kind_of?(Array) ? input.map {|i| tuple[i]} : tuple[input]
          end
          outputs = (testcase["outputs"] || []).map do |output|
            output.kind_of?(Array) ? output.map {|i| tuple[i]} : tuple[output]
          end
          data_null_tuples = (testcase["data_null_tuples"] || []).map do |pos|
            Tuple::DataNullTuple.new(position: pos-1)
          end
          vtable = VariableTable.new

          testcase["criteria"].each do |criterion, truth|
            it "should be %s on criterion of %s" % [truth, criterion] do
              UC.send("%s?" % criterion, rule, inputs, outputs, vtable, data_null_tuples).should == truth
            end
          end

          it "should get update order" do
            order = testcase["order"]
            order = order.to_sym if order
            UC.order(rule, inputs, outputs, vtable, data_null_tuples).should == order
          end
        end
      end
    end
  end
end
