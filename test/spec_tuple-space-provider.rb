require 'innocent-white/tuple-space-server'
require 'innocent-white/tuple-space-provider'

include InnocentWhite

Thread.abort_on_exception = true

describe "TupleSpaceProvider" do
  it "should get provider" do
    p1 = TupleSpaceProvider.get
    p2 = TupleSpaceProvider.get
    p3 = TupleSpaceProvider.get
    p1.uuid.should == p2.uuid
    p3.uuid.should == p3.uuid
  end

  it "should add tuple space server" do
    ts_server = TupleSpaceServer.new(task_worker_resource: 4)
    provider = TupleSpaceProvider.get
    provider.add(ts_server)
    provider.tuple_space_servers.map{|ts| ts.uuid}.first.should == ts_server.uuid
  end
end

