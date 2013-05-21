require_relative '../test-util'

class TestSender
  include Pione::TupleSpaceServerInterface
  include Pione::Log::MessageLog

  def initialize(ts)
    @__tuple_space_server__ = ts
  end
end

describe "Pione::Log::MessageLog" do
  before do
    tuple_space_server = create_tuple_space_server
    @ts = tuple_space_server
    @messenger = Agent[:messenger].new(tuple_space_server)
    class << @messenger
      attr_accessor :msgs
      define_method(:puts) {|msg| @msgs << msg}
    end
    @messenger.msgs = []
    @sender = TestSender.new(@ts)
  end

  after do
    @messenger.terminate
  end

  it "should send user message" do
    @sender.user_message("test message", 0, "test head")
    @messenger.transit
    @messenger.transit
    @messenger.msgs.size.should == 1
  end

  it "should send debug message" do
    Log::MessageLog.debug_mode do
      @sender.debug_message("test message", 0, "test head")
    end
    @messenger.transit
    @messenger.transit
    @messenger.msgs.size.should == 1
  end
end
