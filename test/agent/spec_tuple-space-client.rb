require 'pione/test-helper'

class TestTupleSpaceClient < Agent::TupleSpaceClient
  set_agent_type :test_tuple_space_client, self

  define_transition :sleep

  chain :init => :sleep

  def transit_to_sleep
    Thread.stop
  end
end

describe 'Pione::Agent::TupleSpaceClient' do
  before do
    @space = TestHelper::TupleSpace.create(self)
  end

  after do
    @space.terminate
  end

  it 'should say "hello"' do
    agent = TestTupleSpaceClient.start(@space)
    agent.wait_until(:sleep)
    t1 = read!(TupleSpace::AgentTuple.new(agent_type: :test_tuple_space_client))
    t1.should.not.nil
    t1.uuid.should == agent.uuid
    agent.terminate
    t2 = read!(TupleSpace::AgentTuple.new(agent_type: :test_tuple_space_client))
    t2.should.nil
  end
end
