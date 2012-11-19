require_relative '../test-util'

describe 'Pione::TupleSpace::TupleSpaceProvider' do
  before do
    DRb.start_service
    Global.front = Front::ClientFront.new(self)
  end

  after do
    DRb.stop_service
  end

  it 'should get provider' do
    p1 = TupleSpaceProvider.instance
    p2 = TupleSpaceProvider.instance
    p3 = TupleSpaceProvider.instance
    p1.uuid.should == p2.uuid
    p3.uuid.should == p3.uuid
  end

  it 'should terminate' do
    provider = TupleSpaceProvider.new
    should.not.raise { provider.terminate }
    provider.terminated?
    provider = TupleSpaceProvider.new
    should.not.raise { provider.terminate }
    provider.terminated?
  end

  it "should add tuple space server" do
    tuple_space_server = TupleSpaceServer.new
    provider = TupleSpaceProvider.new
    provider.add_tuple_space_server(tuple_space_server)
    provider.tuple_space_servers.map{|ts| ts.uuid}.first.should == tuple_space_server.uuid
  end
end
