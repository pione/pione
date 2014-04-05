require 'pione/test-helper'

describe Pione::Notification::Transmitter do
  it "should transmit a notification message by UDP broadcast" do
    message = Notification::Message.new("SPEC_NOTIFICATION_SENDER", "SPEC_TEST", {})

    transmitter = Notification::Transmitter.new(URI.parse("pnb://255.255.255.255:56000"))
    should.not.raise {transmitter.transmit(message)}
  end

  it "should send a notification message by UDP multicast" do
    message = Notification::Message.new("SPEC_NOTIFICATION_SENDER", "SPEC_TEST", {})

    transmitter = Notification::Transmitter.new(URI.parse("pnm://239.1.2.3:56000"))
    should.not.raise {transmitter.transmit(message)}
  end

  it "should send a notification message by UDP multicast with a specific interface" do
    message = Notification::Message.new("SPEC_NOTIFICATION_SENDER", "SPEC_TEST", {})

    transmitter = Notification::Transmitter.new(URI.parse("pnm://239.1.2.3:56000?if=127.0.0.1"))
    should.not.raise {transmitter.transmit(message)}
  end

  it "should send a notification by UDP unicast" do
    message = Notification::Message.new("SPEC_NOTIFICATION_SENDER", "SPEC_TEST", {})

    transmitter = Notification::Transmitter.new(URI.parse("pnu://127.0.0.1:56000"))
    should.not.raise {transmitter.transmit(message)}
  end

  it "should raise an argument error" do
    should.raise(ArgumentError) do
      Notification::Transmitter.new(URI.parse("http://127.0.0.1:56000"))
    end
  end
end
