require_relative "../test-util"

describe "Pione::Util::IPAddress" do
  it "should get my IP address" do
    address = Util::IPAddress.myself
    address.should.kind_of(String)
    address.size.should > 0
  end

  it "should find IP addresses" do
    addresses = Util::IPAddress.find
    addresses.should.kind_of(Array)
    addresses.size.should > 0
  end
end
