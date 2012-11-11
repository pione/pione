module Pione
  module Agent
    # @api private
    @table = Hash.new

    class << self
      # Returns a class corresponding to the agent type.
      # @param [Symbol] type
      #   agent type
      # @return [Pione::Agent::BasicAgent]
      #   agent class
      def [](type)
        @table[type]
      end

      # Sets an agent of the system.
      # @param [Pione::Agent::BasicAgent] klass
      #   agent class
      # @return [void]
      def set_agent(klass)
        @table[klass.agent_type] = klass
      end
    end

    # Aborting is an exception for aborting agents.
    class Aborting < Exception; end

    # TransitionError happens when
    class TransitionError < StandardError; end

    # TimeoutStateWaiting happens when not reached expected in time.
    class TimeoutStateWaiting < StandardError
      # expected status
      attr_reader :expected

      # current status
      attr_reader :current

      # Creates an exception.
      #
      # @param [Symbol] expected
      #   expected state
      # @param [Symbol] current
      #   current state
      def initialize(expected, current)
        @expected = expected
        @current = current
      end

      # @private
      def message
        msg = "expected state is '%s' but current state is '%s'"
        msg % [@expected_state, @current_state]
      end
    end

    # StateTransitionSingleMethod provides state transition singleton methods.
    module StateTransitionSingletonMethod
      # Sets pre-defined states when the module is extended by others.
      # @api private
      def self.extended(mod)
        mod.define_state :initialized
        mod.define_state :terminated
        mod.define_state :error

        mod.define_state_transition :error => :terminated
      end

      # Defines new agent state.
      # @param [Symbol] name
      #   state name
      # @return [void]
      def define_state(name)
        @states ||= []
        unless @states.include?(name)
          @states << name

          # define an instance method for checking current state
          define_method("#{name}?") do
            @__current_state__ == name
          end

          # define an instance method for transition
          unless method_defined?("transit_to_#{name}")
            define_method("transit_to_#{name}"){}
          end
        end
      end

      # Returns all states.
      # @return [Array<Symbol>]
      #   state name list
      def states
        @states
      end

      # Returns state transition table.
      # @return [Hash{Symbol => Symbol}]
      #   state transition table
      def state_transition_table
        @__state_transition_table__ ||= {nil => :initialized}
      end

      # Defines a state transition.
      # @param [Hash{Symbol => Symbol}] data
      #   state transition as the key value pair of from-state and to-state
      # @return [void]
      def define_state_transition(data)
        table = state_transition_table
        table.merge!(data)
      end

      # Returns exception handler table.
      # @return [Hash{Symbol => Symbol}]
      #   exception handler table
      def exception_handler_table
        @__exception_handler_table__ ||= {}
      end

      # Defines a state for handling exceptions.
      # @param [Hash{Exception => Symbol}] data
      #   exception handler definition
      # @return [void]
      # @example
      #   define_exception_handler(StopIetration => :end_process)
      def define_exception_handler(data)
        table = exception_handler_table
        table.merge!(data)
      end

      # Creates an agent and starts it.
      # @param [Array<Object>] args
      #   arguments of state change
      def start(*args, &b)
        agent = new(*args)
        b.call(self) if block_given?
        agent.start
        return agent
      end

      # Returns list of exceptions
      # @return [Array<Exception>]
      #   exceptions
      def known_exceptions
        exception_handler_table.keys
      end
    end

    # StateTransitionMethod provides state transition methods.
    module StateTransitionMethod
      # State transition thread.
      attr_reader :running_thread

      # Start agent activity.
      # @return the agent
      def start
        raise TransitionError.new(current_state) if current_state == :terminated

        @__result__ = nil
        @running_thread = Thread.new { start_running }
        return self
      end

      # Return state of current agent.
      # @return [Symbol]
      #   state of current agent
      def current_state
        @__current_state__ ||= nil
      end

      # Transits to next state.
      # @return [void]
      def transit
        # raise error if the current state is terminated
        if current_state == :terminated
          raise TransitionError.new(current_state)
        end

        state_transition_table = self.class.state_transition_table

        begin
          next_state = get_next_state(state_transition_table[current_state])
          set_current_state(next_state)
          @__result__ = call_transition_method(next_state, *@__result__)
        rescue Aborting => e
          raise e
        rescue Object => e
          if self.class.known_exceptions.include?(e.class)
            # known exception
            next_state = get_next_state(exception_handler(e))
            set_current_state(next_state)
            @__result__ = call_transition_method(next_state, e)
          else
            # unknown exception
            raise e
          end
        end
      end

      # Sleep till the agent becomes the state.
      def wait_till(state, sec=5)
        begin
          timeout(sec) do
            sleep 0.1 while not(current_state == state)
          end
        rescue Timeout::Error
          raise TimeoutStateWaiting.new(state, current_state)
        end
      end

      # Terminate to transit.
      def terminate
        # abort the agent when called by other thread
        abort unless @running_thread == Thread.current
        # transit to terminated
        begin
          res = call_transition_method(:terminated)
        rescue DRb::DRbConnError
        end
        # set agent state
        set_current_state(:terminated)
        return res
      end

      private

      # Set new agent's state.
      def set_current_state(state)
        @__current_state__ = state
      end

      # Return a transition method of the state.
      def transition_method(state)
        method("transit_to_#{state}")
      end

      # Call a transition method.
      def call_transition_method(state, *args)
        method = transition_method(state)
        arity = method.arity
        _args = args[0...arity]
        method.call(*_args)
      end

      # Return the handling state for the exception.
      def exception_handler(e)
        handler = nil
        table = self.class.exception_handler_table
        e.class.ancestors.each do |mod|
          if table.has_key?(mod)
            handler = table[mod]
            break
          end
        end
        return handler || :error
      end

      # Start to transit agent's state.
      # For example, logger should transit initialized, logging, logging, ...
      def start_running
        begin
          while not(terminated?)
            transit
          end
        rescue Aborting
          # do nothing, agent will be dead...
        end
      end

      def get_next_state(state)
        next_state = state.kind_of?(Proc) ? state.call(self, @__result__) : state
        unless next_state
          msg = "unknown state transition: #{current_state} -> #{state} at #{self}"
          raise ScriptError.new(msg)
        end
        return next_state
      end

      # Abort the agent.
      def abort
        if @running_thread.alive?
          # raise Aborting exception
          @running_thread.raise Aborting
          # wait to stop the thread
          @running_thread.join
        end if @running_thread
      end
    end

    # BasicAgent is a super class for PIONE agents.
    class BasicAgent < PioneObject
      include DRbUndumped
      extend StateTransitionSingletonMethod
      include StateTransitionMethod

      def self.inherited(subclass)
        states.each {|state| subclass.define_state state }
        define_state_transition(state_transition_table)
      end

      # Set the agent type.
      def self.set_agent_type(agent_type)
        @agent_type = agent_type
      end

      # Return the agent type.
      def self.agent_type
        @agent_type
      end

      # Return agent type of the object.
      def agent_type
        self.class.agent_type
      end

      def transit_to_error(e)
        terminate
      end
    end
  end
end
