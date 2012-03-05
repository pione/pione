require 'innocent-white/test-util'
require 'innocent-white/agent/rule-provider'

describe "Agent::RuleProvider" do
  before do
    create_remote_tuple_space_server
    @provider = Agent[:rule_provider].start(get_tuple_space_server)
    doc = Document.new do
      action('abc') do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content "echo 'abc' > {$OUTPUT[1]}"
      end
      action('xyz') do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content "echo 'xyz' > {$OUTPUT[1]}"
      end
    end
    @rule_abc = doc['abc']
    @rule_xyz = doc['xyz']
    @provider.read_document(doc)
  end

  it "should provide known rule information" do
    # wait provider's setup
    @provider.wait_till(:request_waiting)
    # write a request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: 'abc'))
    check_exceptions
    # check rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: 'abc'))
      rule.status.should == :known
      rule.content.class.should == Rule::ActionRule
      rule.content.should == @rule_abc
    end
    # write another request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: 'xyz'))
    check_exceptions
    # check rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: 'xyz'))
      rule.status.should == :known
      rule.content.class.should == Rule::ActionRule
      rule.content.should == @rule_xyz
    end
  end

  it "should provide unknown rule information" do
    # wait provider's setup
    @provider.wait_till(:request_waiting)
    # write a request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: "aaa"))
    check_exceptions
    # check unknown rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: "aaa"))
      rule.status.should == :unknown
    end
  end
end
