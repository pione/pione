require 'pione/test-helper'

TestHelper.scope do |this|
  class TestSender
    include Pione::TupleSpace::TupleSpaceInterface
    include Pione::Log::MessageLog

    def initialize(tuple_space)
      set_tuple_space(tuple_space)
    end
  end

  describe Pione::Log::MessageLog do
    before do
      @io = StringIO.new("", "w+")
      tuple_space_server = TestHelper::TupleSpace.create(self)
      receiver = Log::CUIMessageLogReceiver.new(@io)
      @ts = tuple_space_server
      @messenger = Agent::Messenger.new(tuple_space_server, receiver, "fake session id")
      @sender = TestSender.new(@ts)
    end

    after do
      @messenger.terminate
    end

    it "should send user message" do
      @sender.user_message("test message", 0, "test head")
      @messenger.start
      sleep 1
      @messenger.terminate
      @messenger.wait_until_terminated
      @io.string.lines.to_a.compact.size.should == 1
    end

    it "should send debug message" do
      Log::MessageLog.debug_mode do
        @sender.debug_message("test message", 0, "test head")
      end
      @messenger.start
      sleep 1
      @messenger.terminate
      @messenger.wait_until_terminated
      @io.string.lines.to_a.compact.size.should == 1
    end
  end
end
