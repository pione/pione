require 'pione/test-helper'

describe Pione::Agent::TaskWorkerBroker do
  before do
    # setup language environment
    @env = TestHelper::Lang.env

    # setup tuple spaces
    @space1 = TupleSpaceServer.new({task_worker_resource: 1}, false)
    @space2 = TupleSpaceServer.new({task_worker_resource: 2}, false)
    @space3 = TupleSpaceServer.new({task_worker_resource: 3}, false)
    [@space1, @space2, @space3].each {|space| space.write(TupleSpace::EnvTuple.new(obj: @env))}

    # setup task worker broker
    Global.expressional_features = Util.parse_features("*")
    @model = Model::TaskWorkerBrokerModel.new
    @model[:spawn_task_worker] = false
    @model[:task_worker_size] = 5
    @broker = Agent::TaskWorkerBroker.new(@model)
  end

  after do
    @broker.terminate
    [@space1, @space2, @space3].each {|space| space.terminate}
  end

  it "should run workers" do
    @broker.start
    @model.quantity.should == 0

    # with space1
    @model.add_tuple_space @space1
    @broker.wait_until_before(:sleep)
    @model.quantity.should == 5
    sleep 0.1 # wait workers to join the space
    @space1.current_task_worker_size.should == 5

    # with space1 and space2
    @model.add_tuple_space @space2
    @broker.wait_until_before(:sleep)
    @model.quantity.should == 5
    sleep 0.1 # wait workers to join the space
    @space1.current_task_worker_size.should == 2
    @space2.current_task_worker_size.should == 3

    # with space1, space2, and space3
    @model.add_tuple_space @space3
    @broker.wait_until_before(:sleep)
    @model.quantity.should == 5
    sleep 0.1 # wait workers to join the space
    @space1.current_task_worker_size.should == 1
    @space2.current_task_worker_size.should == 2
    @space3.current_task_worker_size.should == 2
  end
end
