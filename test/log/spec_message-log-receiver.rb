require 'pione/test-helper'

describe Pione::Log::CUIMessageLogReceiver do
  before do
    @io = StringIO.new("", "w+")
    @receiver = Log::CUIMessageLogReceiver.new(@io)
  end

  it "should receive a message" do
    @receiver.receive("test message", 0, "TEST", :red)
    @io.string.chomp.should == "%s test message" % " TEST".color(:red)
  end
end
