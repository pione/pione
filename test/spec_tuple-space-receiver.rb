require 'innocent-white/tuple-space-receiver'
require 'innocent-white/tuple-space-provider'
require 'innocent-white/tuple-space-server'

include InnocentWhite

Thread.abort_on_exception

describe "TupleSpaceReceiver" do
  it "should get the receiver" do
    r1 = TupleSpaceReceiver.get
    r2 = TupleSpaceReceiver.get
    r3 = TupleSpaceReceiver.get
    r1.uuid.should == r2.uuid
    r2.uuid.should == r3.uuid
  end

  it "should receive tuple space servers" do
    ts_server = TupleSpaceServer.new(task_worker_resource: 4)
    provider = TupleSpaceProvider.get(provider_port: 20000, udp_port: 9999)
    receiver = TupleSpaceReceiver.get(receiver_port: 20001, udp_port: 9999)
    provider.add(ts_server)
    sleep 0.1 # wait to received the packet...
    servers = receiver.tuple_space_servers
    servers.size.should == 1
    servers.first.uuid.should == ts_server.uuid
  end
end

