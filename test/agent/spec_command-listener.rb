require_relative '../test-util'

class TestCommandListener < Pione::Agent::TupleSpaceClient
  define_state :test

  define_state_transition :initialized => :test
  define_state_transition :test => :test

  def transit_to_test
    sleep 0.1
  end
end

describe 'Pione::Agent::CommandListener' do
  before do
    create_remote_tuple_space_server
  end

  after do
    DRb.stop_service
  end

  it 'should terminate' do
    agent = TestCommandListener.start(tuple_space_server)
    agent.wait_till(:test)
    write(Tuple[:command].new("terminate"))
    agent.wait_till(:terminated)
    agent.should.be.terminated
  end
end
