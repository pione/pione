require_relative '../test-util'

path = Pathname.new(File.join(File.dirname(__FILE__), "spec_update-criteria.pione"))
document = Document.parse(path.read)

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
    rule = document["&main:%s" % rule_name]
    describe rule_name do
      cases.each do |case_name, testcase|
        describe case_name do
          testcase["criteria"].each do |criterion, truth|
            it "should be %s on criterion of %s" % [truth, criterion] do
              inputs = testcase["inputs"].map do |input|
                input.kind_of?(Array) ? input.map {|i| tuple[i]} : tuple[input]
              end
              outputs = (testcase["outputs"] || []).map do |output|
                output.kind_of?(Array) ? output.map {|i| tuple[i]} : tuple[output]
              end
              vtable = VariableTable.new
              UC.send("%s?" % criterion, rule, inputs, outputs, vtable).should == truth
            end
          end
        end
      end
    end
  end
end
