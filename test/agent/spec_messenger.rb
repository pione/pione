require 'pione/test-helper'

describe Pione::Agent::Messenger do
  before do
    @io = StringIO.new("", "w+")
    tuple_space = TestHelper::TupleSpace.create(self)
    receiver = Log::CUIMessageLogReceiver.new(@io)
    @messenger = Agent::Messenger.new(tuple_space, receiver, "fake session id")
  end

  after do
    @messenger.terminate
  end

  it "should take messages" do
    write(TupleSpace::MessageTuple.new(type: "test", head: "test", color: :green, contents: "test", level: 0))
    @messenger.start
    sleep 1
    @io.string.lines.to_a.compact.size.should == 1
  end
end

