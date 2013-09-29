require 'pione/test-helper'

describe "Pione::Agent::Broker" do
  before do
    # setup language environment
    @env = TestHelper::Lang.env

    # setup tuple spaces
    @space1 = TupleSpaceServer.new({task_worker_resource: 1}, false)
    @space2 = TupleSpaceServer.new({task_worker_resource: 2}, false)
    @space3 = TupleSpaceServer.new({task_worker_resource: 3}, false)
    [@space1, @space2, @space3].each {|space| space.write(TupleSpace::EnvTuple.new(obj: @env))}

    # setup broker
    Global.expressional_features = Util.parse_features("*")
    @broker = Agent::Broker.new(spawn_task_worker: false, task_worker_resource: 5)
  end

  after do
    @broker.terminate
    [@space1, @space2, @space3].each {|space| space.terminate}
  end

  it "should run workers" do
    @broker.start
    @broker.quantity.should == 0

    # with space1
    @broker.add_tuple_space @space1
    @broker.wait_until_before(:sleep)
    @broker.quantity.should == 5
    sleep 0.1 # wait workers to join the space
    @space1.current_task_worker_size.should == 5

    # with space1 and space2
    @broker.add_tuple_space @space2
    @broker.wait_until_before(:sleep)
    @broker.quantity.should == 5
    sleep 0.1 # wait workers to join the space
    @space1.current_task_worker_size.should == 2
    @space2.current_task_worker_size.should == 3

    # with space1, space2, and space3
    @broker.add_tuple_space @space3
    @broker.wait_until_before(:sleep)
    @broker.quantity.should == 5
    sleep 0.1 # wait workers to join the space
    @space1.current_task_worker_size.should == 1
    @space2.current_task_worker_size.should == 2
    @space3.current_task_worker_size.should == 2
  end
end
