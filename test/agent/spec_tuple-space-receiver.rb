require_relative '../test-util'

describe "Pione::Agent::TupleSpaceReceiver" do
  before do
    @space = create_tuple_space_server
    @broker = Agent::Broker.start("*", task_worker_resource: 5, spawn_task_worker: false)
    @provider_front = Front::TupleSpaceProviderFront.new(StructX.new(:tuple_space_server).new(@space), @space)
  end

  after do
    @broker.terminate
    @space.terminate
    @provider_front.terminate
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

    # wait the receiver to receive a packet
    receiver.wait_until_after(:receive_packet, 10)

    servers = receiver.tuple_space_servers
    servers.size.should == 1
    servers.first.should == @space
    provider.terminate
    receiver.terminate
    provider.wait_until_terminated
    receiver.wait_until_terminated
    provider.should.terminated
    receiver.should.terminated
  end
end
