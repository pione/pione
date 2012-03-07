require 'innocent-white/tuple-space-receiver'
require 'innocent-white/tuple-space-provider'
require 'innocent-white/tuple-space-server'

include InnocentWhite

Thread.abort_on_exception

describe "TupleSpaceReceiver" do
  after do
    TupleSpaceProvider.terminate
    TupleSpaceReceiver.terminate
  end

  it "should get the receiver" do
    r1 = TupleSpaceReceiver.instance
    r2 = TupleSpaceReceiver.instance
    r3 = TupleSpaceReceiver.instance
    r1.uuid.should == r2.uuid
    r2.uuid.should == r3.uuid
  end

  it "should receive tuple space servers" do
    ts_server = TupleSpaceServer.new(task_worker_resource: 4)
    provider = TupleSpaceProvider.instance
    receiver = TupleSpaceReceiver.instance
    provider.add(ts_server)
    sleep 2 # wait to received the packet...
    servers = receiver.tuple_space_servers
    servers.size.should == 1
    servers.first.uuid.should == ts_server.uuid
  end
end

