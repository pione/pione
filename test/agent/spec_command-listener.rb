require_relative '../test-util'

class TestCommandListener < Agent::TupleSpaceClient
  define_state :test

  define_state_transition :initialized => :test
  define_state_transition :test => :test

  def transit_to_test
    sleep 0.1
  end
end

describe 'Agent::CommandListener' do
  before do
    create_remote_tuple_space_server
  end

  after do
    tuple_space_server.terminate
  end

  it 'should terminate' do
    ts = TestCommandListener.start(tuple_space_server)
    ts.wait_till(:test)
    tuple_space_server.write(Tuple[:command].new("terminate"))
    ts.wait_till(:terminated)
    ts.should.terminated
  end
end
