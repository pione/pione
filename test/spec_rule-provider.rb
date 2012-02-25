require 'innocent-white/test-util'
require 'innocent-white/agent/rule-provider'
require 'innocent-white/document'

describe "ModuleProvider" do
  before do
    ts_server = create_remote_tuple_space_server
    @provider = Agent[:rule_provider].new(ts_server)
    doc = Document.new do
      action('abc') do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content "echo 'abc' > {$OUTPUT[1].PATH}"
      end
      action('xyz') do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content "echo 'xyz' > {$OUTPUT[1].PATH}"
      end
    end
    @rule_abc = doc['abc']
    @rule_xyz = doc['xyz']
    @provider.read(doc)
  end

  it "should provide known rule information" do
    @provider.wait_till(:request_waiting)
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: 'abc'))
    check_exceptions
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: 'abc'))
      rule.status.should == :known
      rule.content.class.should == Rule::ActionRule
      rule.content.should == @rule_abc
    end
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: 'xyz'))
    check_exceptions
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(path: 'xyz'))
      rule.status.should == :known
      rule.content.class.should == Rule::ActionRule
      rule.content.should == @rule_xyz
    end
  end

  it "should provide unknown rule information" do
    @provider.wait_till(:request_waiting)
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: "aaa"))
    check_exceptions
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: "aaa"))
      rule.status.should == :unknown
    end
  end
end
