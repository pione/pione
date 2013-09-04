require_relative '../test-util'

describe "Pione::Agent::Broker" do
  before do
    DRb.start_service
    @env = TestUtil::Lang.env
    @space1 = TupleSpaceServer.new(task_worker_resource: 1)
    @space2 = TupleSpaceServer.new(task_worker_resource: 2)
    @space3 = TupleSpaceServer.new(task_worker_resource: 3)
    [@space1, @space2, @space3].each {|space| space.write(Tuple[:env].new(obj: @env))}
    @broker = Agent::Broker.new("*", task_worker_resource: 5, spawn_task_worker: false)
  end

  after do
    @broker.terminate
    [@space1, @space2, @space3].each {|space| space.terminate}
  end

  it "should run workers" do
    @broker.start
    @broker.task_workers.size.should == 0

    # with space1
    @broker.add_tuple_space @space1
    @broker.wait_until_before(:sleep)
    @broker.task_workers.size.should == 5
    @space1.current_task_worker_size.should == 5

    # with space1 and space2
    @broker.add_tuple_space @space2
    @broker.wait_until_before(:sleep)
    @broker.task_workers.size.should == 5
    @space1.current_task_worker_size.should == 2
    @space2.current_task_worker_size.should == 3

    # with space1, space2, and space3
    @broker.add_tuple_space @space3
    @broker.wait_until_before(:sleep)
    @broker.task_workers.size.should == 5
    @space1.current_task_worker_size.should == 1
    @space2.current_task_worker_size.should == 2
    @space3.current_task_worker_size.should == 2
  end
end
