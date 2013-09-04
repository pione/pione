require_relative '../test-util'

describe 'Pione::Agent::TupleSpaceProvider' do
  before do
    @space = create_tuple_space_server
    @front = Front::TupleSpaceProviderFront.new(StructX.new(:tuple_space).new(@space), @space)
    @orig = Global.presence_notification_addresses
  end

  after do
    @front.terminate
    Global.presence_notification_addresses = @orig
  end

  it 'should start activity' do
    provider = Agent::TupleSpaceProvider.start(@front)
    provider.wait_until_after(:send_packet, 10)
    provider.should.not.terminated
  end

  it 'should terminate' do
    provider = Agent::TupleSpaceProvider.start(@front)
    should.not.raise { provider.terminate }
    provider.should.terminated
  end
end
