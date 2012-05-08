require 'innocent-white/test-util'

class TestAgentType < Agent::Base
  set_agent_type :test_agent_type
end

class TestStateTransition < Agent::Base
  define_state :test1
  define_state :test2
  define_state :test3

  define_state_transition :initialized => :test1
  define_state_transition :test1 => :test2
  define_state_transition :test2 => :test3
  define_state_transition :test3 => :terminated
end

class TestLoopStateTransition < Agent::Base
  define_state :test

  define_state_transition :initialized => :test
  define_state_transition :test => :test
end

class TestConditionalStateTransition < Agent::Base
  define_state :test
  define_state :testA
  define_state :testB

  define_state_transition :initialized => :test
  define_state_transition :test => lambda{|agent,result| agent.next_state }
  define_state_transition :testA => :test
  define_state_transition :testB => :test

  attr_reader :next_state

  def transit_to_test
    case @next_state
    when nil
      @next_state = :testA
    when :testA
      @next_state = :testB
    when :testB
      @next_state = :terminated
    end
  end
end

class TestExceptionTransition < Agent::Base
  define_state :test
  define_state :ehandler

  define_state_transition :initialized => :test
  define_state_transition :test => :terminated
  define_state_transition :ehandler => :terminated

  define_exception_handler RuntimeError => :ehandler

  def transit_to_test
    raise RuntimeError.new(:test_exception)
  end

  def transit_to_ehandler(e)
  end
end

describe 'Agent::Base' do
  describe 'agent type' do
    it 'should get the agent type' do
      TestAgentType.agent_type.should == :test_agent_type
      TestAgentType.new.agent_type.should == :test_agent_type
    end
  end

  describe 'simple transition' do
    it 'should return states' do
      states = TestStateTransition.states
      states.should.include :initialized
      states.should.include :test1
      states.should.include :test2
      states.should.include :test3
      states.should.include :terminated
      states.should.include :error
    end

    it 'should transit' do
      ts = TestStateTransition.new
      ts.current_state.should == nil
      ts.transit
      ts.should.initialized
      ts.transit
      ts.should.test1
      ts.transit
      ts.should.test2
      ts.transit
      ts.should.test3
      ts.transit
      ts.should.terminated
      should.raise(Agent::TransitionError) { ts.transit }
    end

    it 'should run' do
      ts = TestStateTransition.start
      ts.wait_till(:terminated)
      ts.should.terminated
      should.raise(Agent::TransitionError) { ts.start }
    end

    it 'should terminate' do
      ts = TestStateTransition.new
      ts.transit # to initialized
      ts.transit # to test1
      ts.terminate
      ts.should.terminated
      should.raise(Agent::TransitionError) { ts.transit }
    end
  end

  describe 'loop transition' do
    it 'should loop' do
      ts = TestLoopStateTransition.new
      100.times { ts.transit }
      ts.should.test
    end

    it 'should terminate' do
      ts = TestLoopStateTransition.start
      sleep 0.1
      ts.terminate
      ts.should.terminated
      should.raise(Agent::TransitionError) { ts.transit }
    end
  end

  describe 'conditional transition' do
    it 'should transit' do
      ts = TestConditionalStateTransition.new
      ts.current_state.should.nil
      ts.transit
      ts.should.initialized
      ts.transit
      ts.should.test
      ts.transit
      ts.should.testA
      ts.transit
      ts.should.test
      ts.transit
      ts.should.testB
      ts.transit
      ts.should.test
      ts.transit
      ts.should.terminated
      should.raise(Agent::TransitionError) { ts.transit }
    end
  end

  describe 'exception handling transition' do
    it 'should handle an exception' do
      ts = TestExceptionTransition.new
      ts.current_state.should.nil
      ts.transit
      ts.should.initialized
      ts.transit
      ts.should.ehandler
      ts.transit
      ts.should.terminated
      should.raise(Agent::TransitionError) { ts.transit }
    end
  end
end
