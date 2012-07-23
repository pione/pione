require_relative '../test-util'

class TestTupleSpaceClient < Agent::TupleSpaceClient
  define_state :test1
  define_state :test2
  define_state :test3

  define_state_transition :initialized => :test1
  define_state_transition :test1 => :test2
  define_state_transition :test2 => :test3
  define_state_transition :test3 => :terminated
end

describe 'Agent::TupleSpaceClient' do
  before do
    create_remote_tuple_space_server
  end

  after do
    tuple_space_server.terminate
  end

  it 'should say hello' do
    ts = TestTupleSpaceClient.new(tuple_space_server)
    ts.current_state.should == nil
    ts.transit
    ts.should.initialized
  end

end
