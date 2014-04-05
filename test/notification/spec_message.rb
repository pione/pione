require 'pione/test-helper'

describe Pione::Notification::Message do
  it "should dump and load" do
    # create a notification message
    message = Notification::Message.new(
      "SPEC_NOTIFICATION", "TEST", {"attr1" => "val1", "attr2" => "val2"}
    )

    # check the message
    message.notifier.should == "SPEC_NOTIFICATION"
    message.type.should == "TEST"
    message["attr1"].should == "val1"
    message["attr2"].should == "val2"
    message.version.should == Notification::Message::PROTOCOL_VERSION

    # dump
    data = message.dump
    data.should.kind_of String

    # load and test
    _message = Notification::Message.load(data)
    _message.should.kind_of Notification::Message
    _message.notifier.should == "SPEC_NOTIFICATION"
    _message.type.should == "TEST"
    _message["attr1"].should == "val1"
    _message["attr2"].should == "val2"
    _message.version.should == Notification::Message::PROTOCOL_VERSION
  end
end
