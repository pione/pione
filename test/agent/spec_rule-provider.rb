require_relative '../test-util'
require 'pione/agent/rule-provider'

describe "Agent::RuleProvider" do
  before do
    create_remote_tuple_space_server
    @provider = Agent[:rule_provider].start(tuple_space_server)
    doc = Document.parse(<<-DOCUMENT)
      Rule abc
        input  '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Action---
        content "echo 'abc' > {$OUTPUT[1]}"
      ---End

      Rule xyz
        input  '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Action---
        content "echo 'xyz' > {$OUTPUT[1]}"
      ---End
    DOCUMENT
    @rule_abc = doc['&main:abc']
    @rule_xyz = doc['&main:xyz']
    @provider.read_document(doc)
  end

  it "should provide known rule information" do
    # wait provider's setup
    @provider.wait_till(:request_waiting)
    # write a request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: '&main:abc'))
    check_exceptions
    # check rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: '&main:abc'))
      rule.status.should == :known
      rule.content.class.should == Rule::ActionRule
      rule.content.should == @rule_abc
    end
    # write another request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: '&main:xyz'))
    check_exceptions
    # check rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      rule = read(Tuple[:rule].new(rule_path: '&main:xyz'))
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
