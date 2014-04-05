require 'pione/test-helper'

class TestAgentType < Agent::BasicAgent
  set_agent_type :test_agent_type, self
end

class TestStateTransition < Agent::BasicAgent
  define_transition :test1
  define_transition :test2
  define_transition :test3

  chain :init => :test1
  chain :test1 => :test2
  chain :test2 => :test3
  chain :test3 => :terminate

  attr_reader :history

  def initialize
    super()
    @history = []
  end

  def transit_to_init
    @history << :init
  end

  def transit_to_test1
    @history << :test1
  end

  def transit_to_test2
    @history << :test2
  end

  def transit_to_test3
    @history << :test3
  end

  def transit_to_terminate
    @history << :terminate
  end
end

class TestLoopStateTransition < Agent::BasicAgent
  define_transition :test

  chain :init => :test
  chain :test => :test
end

class TestConditionalStateTransition < Agent::BasicAgent
  define_transition :test
  define_transition :testA
  define_transition :testB

  chain :init => :test
  chain :test => lambda{|agent,result| agent.next_transition }
  chain :testA => :test
  chain :testB => :test

  attr_reader :next_transition
  attr_reader :a
  attr_reader :b

  def initialize
    super()
    @a = 0
    @b = 0
  end

  def transit_to_test
    case @next_transition
    when nil
      @next_transition = :testA
    when :testA
      @next_transition = :testB
    when :testB
      @next_transition = :terminate
    end
  end

  def transit_to_testA
    @a += 1
  end

  def transit_to_testB
    @b += 1
  end
end

class TestExceptionTransition < Agent::BasicAgent
  define_transition :test
  define_transition :ehandler

  chain :init => :test
  chain :test => :terminate
  chain :ehandler => :terminate

  define_exception_handler RuntimeError => :ehandler

  attr_reader :ehandled

  def initialize
    super()
    @ehandled = 0
  end

  def transit_to_test
    raise RuntimeError.new(:test_exception)
  end

  def transit_to_ehandler(e)
    @ehandled +=1
  end
end

describe Pione::Agent::BasicAgent do
  describe 'agent type' do
    it 'should get the agent type' do
      TestAgentType.agent_type.should == :test_agent_type
      TestAgentType.new.agent_type.should == :test_agent_type
    end
  end

  describe 'simple transition' do
    it 'should transit' do
      agent = TestStateTransition.start
      agent.wait_until_terminated
      agent.should.terminated
      agent.history.should == [:init, :test1, :test2, :test3, :terminate]
    end

    it 'should run' do
      agent = TestStateTransition.start
      agent.wait_until_terminated
      agent.should.terminated
    end

    it 'should terminate' do
      agent = TestStateTransition.start
      agent.terminate
      agent.wait_until_terminated
      agent.should.terminated
    end
  end

  describe 'loop transition' do
    it 'should loop' do
      agent = TestLoopStateTransition.new
      should.raise(Timeout::Error) do
        timeout(3) do
          agent.start
          agent.chain_threads.list.each {|th| th.join}
        end
      end
      agent.terminate
      agent.should.terminated
    end

    it 'should terminate' do
      agent = TestLoopStateTransition.start
      sleep 1
      agent.terminate
      agent.should.terminated
    end
  end

  describe 'conditional transition' do
    it 'should transit' do
      agent = TestConditionalStateTransition.start
      agent.wait_until_terminated
      agent.should.terminated
      agent.a.should == 1
      agent.b.should == 1
    end
  end

  describe 'exception handling transition' do
    it 'should handle an exception' do
      agent = TestExceptionTransition.start
      agent.wait_until_terminated
      agent.should.terminated
      agent.ehandled.should == 1
    end
  end
end
