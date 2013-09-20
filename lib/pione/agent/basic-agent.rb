module Pione
  module Agent
    @table = Hash.new

    class << self
      # Returns a class corresponding to the agent type.
      def [](type)
        @table[type]
      end

      # Sets an agent of the system.
      def set_agent(klass)
        @table[klass.agent_type] = klass
      end
    end

    # StateTransitionSingleMethod provides state transition singleton methods.
    module StateTransitionSingletonMethod
      # Defines a new transition.
      def define_transition(name)
        @transitions ||= []
        unless @transitions.include?(name)
          @transitions << name

          # define empty transition method
          unless method_defined?("transit_to_#{name}")
            define_method("transit_to_#{name}") {}
          end
        end
      end

      # Returns transition chain table.
      def transition_chain
        @transition_chain ||= {nil => :init}
      end

      # Define a transition chain.
      def chain(data)
        data.each do |k, v|
          raise ArgumentError.new(k) if not(@transitions.include?(k))
          if not(v.is_a?(Proc))
            (v.is_a?(Array) ? v : [v]).each do |_v|
              raise ArgumentError.new(_v) if not(@transitions.include?(_v))
            end
          end
        end
        transition_chain.merge!(data)
      end

      # Return exception handler table.
      def exception_handler
        @exception_handler ||= {}
      end

      # Define a transition for handling exceptions.
      def define_exception_handler(data)
        exception_handler.merge!(data)
      end

      # Creates an agent and starts it.
      def start(*args, &b)
        agent = new(*args, &b)
        return agent.start
      end
    end

    # BasicAgent is a super class for all PIONE agents.
    class BasicAgent < PioneObject
      include DRbUndumped
      extend StateTransitionSingletonMethod

      #
      # variables
      #

      @transitions = Array.new
      @transition_chain = Hash.new
      @exception_handler = Hash.new

      #
      # default transitions
      #

      define_transition :init
      define_transition :terminate

      #
      # class methods
      #

      def self.inherited(subclass)
        subclass.instance_variable_set(:@transitions, @transitions.clone)
        subclass.instance_variable_set(:@transition_chain, @transition_chain.clone)
        subclass.instance_variable_set(:@exception_handler, @exception_handler.clone)
      end

      # Set the agent type.
      def self.set_agent_type(agent_type, klass=nil)
        @agent_type = agent_type
        Agent.set_agent(klass) if klass
      end

      # Return the agent type.
      def self.agent_type
        @agent_type
      end

      #
      # instance methods
      #

      forward :class, :agent_type
      attr_reader :chain_threads # transition chain thread group

      def initialize
        @chain_threads = ThreadGroup.new

        # for wait_until_before method
        @__wait_until_before_mutex__ = Mutex.new
        @__wait_until_before_cv__ = Hash.new {|h, k| h[k] = ConditionVariable.new}

        # for wait_until_after method
        @__wait_until_after_mutex__ = Mutex.new
        @__wait_until_after_cv__ = Hash.new {|h, k| h[k] = ConditionVariable.new}
      end

      # Start agent activity.
      def start
        unless @chain_threads.list.empty?
          raise TerminationError.new(self, states)
        end

        # save current thread
        @__owner_thread__ = Thread.current

        # start a new chain thread
        @chain_threads.add(start_running(:init, [], AgentState.new, true))
        @chain_threads.enclose

        return self
      end

      # Fire the transtion with inputs.
      def transit(transition, transition_inputs)
        # wake up threads that wait by wait_until_before method
        if @__wait_until_before_cv__.has_key?(transition)
          @__wait_until_before_mutex__.synchronize do
            @__wait_until_before_cv__[transition].broadcast
          end
        end

        # mark current transition
        Thread.current[:agent_state] =
          AgentState.new(previous: Thread.current[:agent_state].previous, current: transition)

        # call transition
        result = call_transition_method(transition, transition_inputs)
        result = result.nil? ? [] : result
        result = result.is_a?(Array) ? result : [result]

        # unmark current transition and mark previous transition
        Thread.current[:agent_state] = AgentState.new(previous: transition, current: nil)

        # wake up threads that wait by wait_until_after method
        if @__wait_until_after_cv__.has_key?(transition)
          @__wait_until_after_mutex__.synchronize do
            @__wait_until_after_cv__[transition].broadcast
          end
        end

        return transition, result
      rescue StandardError => e
        # error handling
        if error_transition = get_exception_handler(e)
          raise unless error_transition.is_a?(Symbol)
          return transit(error_transition, [e])
        else
          if @__owner_thread and @__owner_thread__.alive?
            @__owner_thread__.raise e
          else
            raise e
          end
        end
      end

      # Return agent states.
      def states
        @chain_threads.list.map {|th| th[:agent_state]}
      end

      # Sleep until before the agent fires the transition.
      def wait_until_before(transition, sec=10)
        timeout(sec) do
          @__wait_until_before_mutex__.synchronize do
            @__wait_until_before_cv__[transition].wait(@__wait_until_before_mutex__)
          end
        end
      rescue Timeout::Error
        raise TimeoutError.new(self, @chain_threads.list.map{|th| th[:agent_state]}, sec)
      end

      def wait_until(transition, sec=10)
        unless @chain_threads.list.any? {|th| th[:agent_state] and th[:agent_state].current == transition}
          wait_until_before(transition, sec)
        end
      end

      # Sleep until after the agent fires the transition.
      def wait_until_after(transition, sec=10)
        timeout(sec) do
          @__wait_until_after_mutex__.synchronize do
            @__wait_until_after_cv__[transition].wait(@__wait_until_after_mutex__)
          end
        end
      rescue Timeout::Error => e
        raise TimeoutError.new(self, @chain_threads.list.map{|th| th[:agent_state]}, sec)
      end

      # Sleep caller thread until the agent is terminated.
      def wait_until_terminated(sec=10)
        unless terminated?
          wait_until_after(:terminate, sec)
          @chain_threads.list.each {|thread| thread.join}
        end
      end

      # Terminate the agent activity.
      def terminate
        state = nil

        Thread.new {

          # kill all chain threads
          @chain_threads.list.each do |thread|
            state = thread[:agent_state] # save last state
            unless thread == Thread.current
              thread.kill
              thread.join
            end
          end

          # fire "terminate" transtion
          begin
            Thread.current[:agent_state] = state || AgentState.new
            transit(:terminate, [])
          rescue DRb::DRbConnError, DRbPatch::ReplyReaderError => e
            Log::Debug.warn("raised a connection error when we terminated", self, e)
          end
        }.join
      end

      # Return true if the agent has been terminated.
      def terminated?
        return (@chain_threads.list.empty? and @chain_threads.enclosed?)
      end

      private

      # Start transition chain.
      def start_running(transition, result, state, free)
        thread = free ? Util::FreeThreadGenerator.method(:generate) : Thread.method(:new)
        thread.call do
          begin
            Thread.current[:agent_state] = state
            while true
              # fire the transition
              # NOTE: transition name is maybe changed by the result of firing
              _transition, result, count = transit(transition, result)
              state = Thread.current[:agent_state]

              begin
                # go next transition
                next_transitions = get_next_transitions(_transition, result)
                transition, *branches = next_transitions
                # handle transition branches
                branches.each {|t| start_running(t, result, state, false)}
              rescue TerminationError
                break # end loop after terminate transition
              end
            end
          rescue Exception => e
            # throw the exception to command's runnning thread
            if Global.command and Global.command.running_thread and Global.command.running_thread.alive?
              Global.command.running_thread.raise e
            else
              raise e
            end
          end
        end
      end

      # Call the transition method.
      def call_transition_method(transition, args)
        method = method("transit_to_#{transition}")
        method.call(*args[0,method.arity])
      end

      # Get transtion for the exception.
      def get_exception_handler(e)
        table = self.class.exception_handler
        e.class.ancestors.each do |mod|
          return table[mod] if table.has_key?(mod)
        end
      end

      # Get next transitions based on transition chain table with previous transition result.
      def get_next_transitions(transition, result)
        next_transitions = self.class.transition_chain[transition]
        if next_transitions.is_a?(Proc)
          next_transitions = next_transitions.call(self, *result)
        end
        if next_transitions.nil? or (next_transitions == [])
          raise TerminationError.new(self, states)
        end
        return next_transitions
      end
    end

    # AgentState represents a state of agent. The state is a pair of previous
    # transiton and current transition.
    class AgentState < StructX
      member :previous
      member :current

      def previous?(state)
        previous == state
      end

      def current?(state)
        current == state
      end

      def to_s
        "<%s=>%s>" % [previous, current]
      end
    end
  end
end
