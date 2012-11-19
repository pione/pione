require_relative '../test-util'

describe "Pione::Agent::Broker" do
  before do
    DRb.start_service
    @broker_front = Pione::Front::BrokerFront.new(self)
    @ts_server1 = TupleSpaceServer.new(task_worker_resource: 1)
    @ts_server2 = TupleSpaceServer.new(task_worker_resource: 2)
    @ts_server3 = TupleSpaceServer.new(task_worker_resource: 3)
    @broker1 = Agent[:broker].new(task_worker_resource: 5)
  end

  after do
    @broker_front.terminate
  end

  it "should run workers" do
    @broker1.start
    @broker1.task_workers.size.should == 0
    @broker1.add_tuple_space_server @ts_server1
    sleep 2
    @broker1.task_workers.size.should == 5
    @ts_server1.current_task_worker_size.should == 5
    @broker1.add_tuple_space_server @ts_server2
    sleep 2
    @broker1.task_workers.size.should == 5
    @ts_server1.current_task_worker_size.should == 2
    @ts_server2.current_task_worker_size.should == 3
    @broker1.add_tuple_space_server @ts_server3
    sleep 2
    @broker1.task_workers.size.should == 5
    @ts_server1.current_task_worker_size.should == 1
    @ts_server2.current_task_worker_size.should == 2
    @ts_server3.current_task_worker_size.should == 2
  end
end
