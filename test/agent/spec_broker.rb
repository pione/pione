require 'innocent-white/tuple-space-server'
require 'innocent-white/agent/broker'

include InnocentWhite

describe "Broker" do
  before do
    @ts_server1 = TupleSpaceServer.new(task_worker_resource: 1)
    @ts_server2 = TupleSpaceServer.new(task_worker_resource: 2)
    @ts_server3 = TupleSpaceServer.new(task_worker_resource: 3)
    @broker1 = Agent[:broker].new(task_worker_resource: 5)
  end

  it "should run workers" do
    @broker1.task_workers.size.should == 0
    @broker1.add_tuple_space_server @ts_server1
    sleep 0.1
    @broker1.task_workers.size.should == 5
    @ts_server1.current_task_worker_size.should == 5
    @broker1.add_tuple_space_server @ts_server2
    sleep 1
    @broker1.task_workers.size.should == 5
    @ts_server1.current_task_worker_size.should == 2
    @ts_server2.current_task_worker_size.should == 3
    @broker1.add_tuple_space_server @ts_server3
    sleep 1
    @broker1.task_workers.size.should == 5
    @ts_server1.current_task_worker_size.should == 1
    @ts_server2.current_task_worker_size.should == 2
    @ts_server3.current_task_worker_size.should == 2
  end
end
