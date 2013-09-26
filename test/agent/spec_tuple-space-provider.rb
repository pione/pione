require 'pione/test-helper'

describe 'Pione::Agent::TupleSpaceProvider' do
  before do
    @tuple_space = TestHelper::TupleSpace.create(self)
    @front = Front::TupleSpaceProviderFront.new(@tuple_space)
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
