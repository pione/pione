require 'pione/test-helper'

TestHelper.scope do |this|
  def this.receive(target_address, receiver_address, context)
    message = Notification::Message.new("SPEC_NOTIFICATION_SENDER", "SPEC_TEST", {})

    Thread.new do
      loop do
        Notification::Transmitter.transmit(message, [URI.parse(target_address)])
        sleep 1
      end
    end

    receiver = Notification::Receiver.new(URI.parse(receiver_address))
    context.should.not.raise do
      Timeout.timeout(5) do
        receiver.receive
        receiver.close
      end
    end
  end

  describe Pione::Notification::Receiver do
    it "should receive a notification from broadcast" do
      this.receive("pnb://127.0.0.255:56000", "pnb://0.0.0.0:56000", self)
    end

    it "should receive a notification from multicast" do
      this.receive("pnm://234.1.2.3:56000", "pnm://234.1.2.3:56000", self)
    end

    it "should receive a notification from unicast" do
      this.receive("pnu://127.0.0.1:56000", "pnu://0.0.0.0:56000", self)
    end
  end
end
