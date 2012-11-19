require_relative '../test-util'

describe "Pione::TupleSpace::TupleSpaceReceiver" do
  after do
    DRb.start_service
  end

  after do
    DRb.stop_service
  end

  it "should get the receiver" do
    should.not.raise do
      receiver = TupleSpaceReceiver.new
      receiver.terminate
      receiver.should.terminated
    end
  end

  it "should receive tuple space servers" do
    tuple_space_server = TupleSpaceServer.new
    provider = TupleSpaceProvider.new
    receiver = TupleSpaceReceiver.new
    provider.add_tuple_space_server(tuple_space_server)
    sleep 1 # wait to received the packet...
    servers = receiver.tuple_space_servers
    servers.size.should == 1
    servers.first.uuid.should == tuple_space_server.uuid
    provider.terminate
    receiver.terminate
  end
end
