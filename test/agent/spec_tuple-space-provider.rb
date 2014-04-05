require 'pione/test-helper'

describe 'Pione::Agent::TupleSpaceProvider' do
  before do
    @tuple_space = TestHelper::TupleSpace.create(self)
    @cmd = Command::BasicCommand.new([])
    @cmd.model[:parent_front] = Front::ClientFront.new(@cmd)
    @cmd.model[:parent_front].set_tuple_space(@tuple_space)
    @front = Front::TupleSpaceProviderFront.new(@cmd)
    @orig = Global.notification_targets
  end

  after do
    @cmd.model[:parent_front].terminate
    @front.terminate
    Global.notification_targets = @orig
  end

  it 'should start activity' do
    provider = Agent::TupleSpaceProvider.start(@front, [URI.parse("pnu://127.0.0.1:3456")])
    provider.wait_until_after(:send_message, 10)
    provider.should.not.terminated
  end

  it 'should terminate' do
    provider = Agent::TupleSpaceProvider.start(@front, [URI.parse("pnu://127.0.0.1:3456")])
    should.not.raise { provider.terminate }
    provider.should.terminated
  end
end
