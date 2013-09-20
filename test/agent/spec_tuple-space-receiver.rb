require_relative '../test-util'

describe "Pione::Agent::TupleSpaceReceiver" do
  before do
    @tuple_space = create_tuple_space_server
    Global.expressional_features = Util.parse_features("*")
    @broker = Agent::Broker.start(task_worker_resource: 5, spawn_task_worker: false)
    @provider_front = Front::TupleSpaceProviderFront.new(@tuple_space)
  end

  after do
    @broker.terminate
    @tuple_space.terminate
    @provider_front.terminate
    Global.expressional_features = nil
  end

  it "should run and terminate receiver" do
    receiver = Agent::TupleSpaceReceiver.start(@broker)
    receiver.wait_until(:receive_packet)
    receiver.terminate
    receiver.wait_until_terminated
    receiver.should.terminated
  end

  it "should receive tuple space servers" do
    provider = Agent::TupleSpaceProvider.start(@provider_front)
    receiver = Agent::TupleSpaceReceiver.start(@broker)

    # wait receiver to handle notification
    receiver.wait_until_after(:receive_packet, 10)
    receiver.notification_handlers.list.each {|thread| thread.join}

    # test tuple spaces
    spaces = receiver.tuple_spaces
    spaces.size.should == 1
    spaces.first.should == @tuple_space

    # terminate agents
    provider.terminate
    receiver.terminate
    provider.wait_until_terminated
    receiver.wait_until_terminated
    provider.should.terminated
    receiver.should.terminated
  end
end
