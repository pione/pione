require 'pione/test-helper'

describe Pione::Location::NotificationBroadcastScheme do
  it "should parse" do
    uri = URI.parse("pnb://255.255.255.255:56000")
    uri.scheme.should == "pnb"
    uri.host.should == "255.255.255.255"
    uri.port.should == 56000
  end
end

describe Pione::Location::NotificationMulticastScheme do
  it "should parse" do
    uri = URI.parse("pnm://239.0.0.1:56000")
    uri.scheme.should == "pnm"
    uri.host.should == "239.0.0.1"
    uri.port.should == 56000
    uri.interface.should.nil
  end

  it "should parse with interface" do
    uri = URI.parse("pnm://239.0.0.1:56000?if=192.168.100.10")
    uri.scheme.should == "pnm"
    uri.host.should == "239.0.0.1"
    uri.port.should == 56000
    uri.interface.should == "192.168.100.10"
  end
end

describe Pione::Location::NotificationUnicastScheme do
  it "should parse" do
    uri = URI.parse("pnu://192.168.100.11:56000")
    uri.scheme.should == "pnu"
    uri.host.should == "192.168.100.11"
    uri.port.should == 56000
  end
end
