require_relative '../test-util'

describe "Pione::Agent::RuleProvider" do
  before do
    @ts = create_tuple_space_server
    @agent = Agent[:rule_provider].new(@ts)
    doc = Component::Document.load(<<-DOCUMENT)
      Rule A
        input  '*.a'
        output '{$I[1]}.result'
      Action
        echo A > {$O[1]}
      End

      Rule B
        input  '*.b'
        output '{$I[1]}.result'
      Action
        echo B > {$[1]}
      End
    DOCUMENT
    @rule_a = doc.find('A')
    @rule_b = doc.find('B')
    @agent.read_rules(doc)
  end

  after do
    @agent.terminate
    @ts.terminate
  end

  it "should have rules" do
    @agent.known_rules.should.include "&Main:A"
    @agent.known_rules.should.include "&Main:B"
  end

  it "should add a rule" do
    doc = Component::Document.load(<<-DOCUMENT)
      Rule C
        input  '*.c'
        output '{$I[1]}.result'
      Action
        echo C > {$O[1]}
      End
    DOCUMENT
    @agent.read_rules(doc)
    @agent.known_rules.should.include "&Main:C"
  end

  it "should provide requested rule" do
    @agent.start

    # wait provider's setup
    @agent.wait_till(:request_waiting)

    # write a request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: '&Main:A'))
    check_exceptions

    # check rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      tuple = read!(Tuple[:rule].new(rule_path: '&Main:A'))
      tuple.content.class.should == Component::ActionRule
      tuple.content.should == @rule_a
    end

    # write another request
    write_and_wait_to_be_taken(Tuple[:request_rule].new(rule_path: '&Main:B'))
    check_exceptions

    # check rule tuple
    should.not.raise(Rinda::RequestExpiredError) do
      tuple = read!(Tuple[:rule].new(rule_path: '&Main:B'))
      tuple.content.class.should == Component::ActionRule
      tuple.content.should == @rule_b
    end
  end
end
