require 'pione/test-helper'

describe Pione::Notification::Address do
  describe "target address" do
    it "should get a URI for a target address \"255.255.255.255:56001\"" do
      uri = Notification::Address.target_address_to_uri("pnb://255.255.255.255:56001")
      uri.scheme.should == "pnb"
      uri.host.should == "255.255.255.255"
      uri.port.should == 56001
    end

    it "should get a URI for a target address \"255.255.255.255\"" do
      uri = Notification::Address.target_address_to_uri("255.255.255.255")
      uri.scheme.should == "pnb"
      uri.host.should == "255.255.255.255"
      uri.port.should == Global.default_notification_target_port
    end

    it "should get a URI for a target address \":56001\"" do
      uri = Notification::Address.target_address_to_uri(":56001")
      uri.scheme.should == "pnb"
      uri.host.should == Global.default_notification_target_host
      uri.port.should == 56001
    end

    it "should get a URI for a target address \"pnb://255.255.255.255:56001\"" do
      uri = Notification::Address.target_address_to_uri("255.255.255.255:56001")
      uri.scheme.should == "pnb"
      uri.host.should == "255.255.255.255"
      uri.port.should == 56001
    end

    it "should get a URI for a target address \"pnb://255.255.255.255\"" do
      uri = Notification::Address.target_address_to_uri("pnb://255.255.255.255")
      uri.scheme.should == "pnb"
      uri.host.should == "255.255.255.255"
      uri.port.should == Global.default_notification_target_port
    end

    it "should get a URI for a target address \"pnb://.:56001\"" do
      uri = Notification::Address.target_address_to_uri("pnb://.:56001")
      uri.scheme.should == "pnb"
      uri.host.should == Global.default_notification_target_host
      uri.port.should == 56001
    end

    it "should get a URI for a target address \"pnu://192.168.100.10:56001\"" do
      uri = Notification::Address.target_address_to_uri("pnu://192.168.100.10:56001")
      uri.scheme.should == "pnu"
      uri.host.should == "192.168.100.10"
      uri.port.should == 56001
    end

    it "should get a URI for a target address \"pnu://192.168.100.10\"" do
      uri = Notification::Address.target_address_to_uri("pnu://192.168.100.10")
      uri.scheme.should == "pnu"
      uri.host.should == "192.168.100.10"
      uri.port.should == Global.default_notification_target_port
    end

    it "should get a URI for a target address \"pnu://.:56001\"" do
      uri = Notification::Address.target_address_to_uri("pnu://.:56001")
      uri.scheme.should == "pnu"
      uri.host.should == Global.default_notification_target_host
      uri.port.should == 56001
    end

    it "should get a URI for a target address \"pnm://239.1.2.3:56001\"" do
      uri = Notification::Address.target_address_to_uri("pnm://239.1.2.3:56001")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == 56001
      uri.interface.should.nil
    end

    it "should get a URI for a target address \"pnm://239.1.2.3\"" do
      uri = Notification::Address.target_address_to_uri("pnm://239.1.2.3")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == Global.default_notification_target_port
      uri.interface.should.nil
    end

    it "should get a URI for a target address \"pnm://.:56001\"" do
      uri = Notification::Address.target_address_to_uri("pnm://.:56001")
      uri.scheme.should == "pnm"
      uri.host.should == Global.default_notification_target_host
      uri.port.should == 56001
      uri.interface.should.nil
    end

    it "should get a URI for a target address \"pnm://239.1.2.3:56001?if=192.168.100.10\"" do
      uri = Notification::Address.target_address_to_uri("pnm://239.1.2.3:56001?if=192.168.100.10")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == 56001
      uri.interface.should == "192.168.100.10"
    end

    it "should get a URI for a target address \"pnm://239.1.2.3?if=192.168.100.10\"" do
      uri = Notification::Address.target_address_to_uri("pnm://239.1.2.3?if=192.168.100.10")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == Global.default_notification_target_port
      uri.interface.should == "192.168.100.10"
    end

    it "should get a URI for a target address \"pnm://.:56001?if=192.168.100.10\"" do
      uri = Notification::Address.target_address_to_uri("pnm://.:56001?if=192.168.100.10")
      uri.scheme.should == "pnm"
      uri.host.should == Global.default_notification_target_host
      uri.port.should == 56001
      uri.interface.should == "192.168.100.10"
    end
  end

  describe "receiver address" do
    it "should get a URI for a receiver address \"0.0.0.0:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("pnb://0.0.0.0:56001")
      uri.scheme.should == "pnb"
      uri.host.should == "0.0.0.0"
      uri.port.should == 56001
    end

    it "should get a URI for a receiver address \"0.0.0.0\"" do
      uri = Notification::Address.receiver_address_to_uri("0.0.0.0")
      uri.scheme.should == "pnb"
      uri.host.should == "0.0.0.0"
      uri.port.should == Global.default_notification_receiver_port
    end

    it "should get a URI for a receiver address \":56001\"" do
      uri = Notification::Address.receiver_address_to_uri(":56001")
      uri.scheme.should == "pnb"
      uri.host.should == Global.default_notification_receiver_host
      uri.port.should == 56001
    end

    it "should get a URI for a receiver address \"pnb://0.0.0.0:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("0.0.0.0:56001")
      uri.scheme.should == "pnb"
      uri.host.should == "0.0.0.0"
      uri.port.should == 56001
    end

    it "should get a URI for a receiver address \"pnb://0.0.0.0\"" do
      uri = Notification::Address.receiver_address_to_uri("pnb://0.0.0.0")
      uri.scheme.should == "pnb"
      uri.host.should == "0.0.0.0"
      uri.port.should == Global.default_notification_receiver_port
    end

    it "should get a URI for a receiver address \"pnb://.:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("pnb://.:56001")
      uri.scheme.should == "pnb"
      uri.host.should == Global.default_notification_receiver_host
      uri.port.should == 56001
    end

    it "should get a URI for a receiver address \"pnu://192.168.100.10:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("pnu://192.168.100.10:56001")
      uri.scheme.should == "pnu"
      uri.host.should == "192.168.100.10"
      uri.port.should == 56001
    end

    it "should get a URI for a receiver address \"pnu://192.168.100.10\"" do
      uri = Notification::Address.receiver_address_to_uri("pnu://192.168.100.10")
      uri.scheme.should == "pnu"
      uri.host.should == "192.168.100.10"
      uri.port.should == Global.default_notification_receiver_port
    end

    it "should get a URI for a receiver address \"pnu://.:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("pnu://.:56001")
      uri.scheme.should == "pnu"
      uri.host.should == Global.default_notification_receiver_host
      uri.port.should == 56001
    end

    it "should get a URI for a receiver address \"pnm://239.1.2.3:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("pnm://239.1.2.3:56001")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == 56001
      uri.interface.should.nil
    end

    it "should get a URI for a receiver address \"pnm://239.1.2.3\"" do
      uri = Notification::Address.receiver_address_to_uri("pnm://239.1.2.3")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == Global.default_notification_receiver_port
      uri.interface.should.nil
    end

    it "should get a URI for a receiver address \"pnm://.:56001\"" do
      uri = Notification::Address.receiver_address_to_uri("pnm://.:56001")
      uri.scheme.should == "pnm"
      uri.host.should == Global.default_notification_receiver_host
      uri.port.should == 56001
      uri.interface.should.nil
    end

    it "should get a URI for a receiver address \"pnm://239.1.2.3:56001?if=192.168.100.10\"" do
      uri = Notification::Address.receiver_address_to_uri("pnm://239.1.2.3:56001?if=192.168.100.10")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == 56001
      uri.interface.should == "192.168.100.10"
    end

    it "should get a URI for a receiver address \"pnm://239.1.2.3?if=192.168.100.10\"" do
      uri = Notification::Address.receiver_address_to_uri("pnm://239.1.2.3?if=192.168.100.10")
      uri.scheme.should == "pnm"
      uri.host.should == "239.1.2.3"
      uri.port.should == Global.default_notification_receiver_port
      uri.interface.should == "192.168.100.10"
    end

    it "should get a URI for a receiver address \"pnm://.:56001?if=192.168.100.10\"" do
      uri = Notification::Address.receiver_address_to_uri("pnm://.:56001?if=192.168.100.10")
      uri.scheme.should == "pnm"
      uri.host.should == Global.default_notification_receiver_host
      uri.port.should == 56001
      uri.interface.should == "192.168.100.10"
    end
  end
end
