require 'timeout'
require 'thread'
require 'monitor'
require 'innocent-white/common'

module InnocentWhite
  module Agent
    TABLE = Hash.new

    # Return a class for agent type.
    def self.[](type)
      TABLE[type]
    end

    # Set a agent of the system.
    def self.set_agent(klass)
      TABLE[klass.agent_type] = klass
    end

    class Aborting < Exception; end

    # StateTransitionSingleMethod provides state transition singleton methods.
    module StateTransitionSingletonMethod
      # Set pre-defined states when the module is extended by others.
      def self.extended(mod)
        mod.define_state :initialized
        mod.define_state :terminated
        mod.define_state :error

        mod.define_state_transition :error => :terminated
      end

      # Define new agent state.
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

      # Return all states.
      def states
        @states
      end

      # Return state transition table.
      def state_transition_table
        @__state_transition_table__ ||= {nil => :initialized}
      end

      # Define a state transition.
      def define_state_transition(data)
        table = state_transition_table
        table.merge!(data)
      end

      # Return exception handler table.
      def exception_handler_table
        @__exception_handler_table__ ||= {}
      end

      # Define a state for handling exceptions.
      def define_exception_handler(data)
        table = exception_handler_table
        table.merge!(data)
      end

      # Create a agent and start it.
      def start(*args, &b)
        agent = new(*args)
        b.call(self) if block_given?
        agent.start
        return agent
      end

      def known_exceptions
        exception_handler_table.keys
      end
    end

    class TransitionError < RuntimeError
    end

    class TimeoutStateWaiting < RuntimeError
    end

    # StateTransitionMethod provides state transition methods.
    module StateTransitionMethod
      # State transition thread.
      attr_reader :running_thread

      # Start agent activity.
      def start
        raise TransitionError.new(current_state) if current_state == :terminated

        @__result__ = nil
        @running_thread = Thread.new { start_running }
        return self
      end

      # Return the current agent's state.
      def current_state
        @__current_state__ ||= nil
      end

      def transit
        raise TransitionError.new(current_state) if current_state == :terminated
        exit unless @running_thread == Thread.current

        state_transition_table = self.class.state_transition_table

        begin
          next_state = get_next_state(state_transition_table[current_state])
          if next_state == :doing_command
              puts "current: #{current_state}"
              puts "@__result__: #{agent_type} #{next_state} >>> #{@__result__}"
            if @__result__.nil? # || @__result__.empty?
              puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
              puts "current: #{current_state}"
              puts "@__result__: #{agent_type} #{next_state} >>> #{@__result__}"
              puts caller
              exit
            end
          end
          set_current_state(next_state)
          @__result__ = call_transition_method(next_state, *@__result__)
        rescue Aborting => e
          raise e
        rescue StandardError => e
          if self.class.known_exceptions.include?(e.class)
            next_state = get_next_state(exception_handler(e))
            set_current_state(next_state)
            @__result__ = call_transition_method(next_state, e)
          else
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
          raise TimeoutStateWaiting.new(current_state)
        end
      end

      # Terminate to transit.
      def terminate
        # abort the agent when called by other thread
        abort unless @running_thread == Thread.current
        # transit to terminated
        res = call_transition_method(:terminated)
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
        if state == :doing_command and _args == []
          puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!"
          puts arity
          p args
          puts caller
        end
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
            puts "### #{self}, result > #{@__result__}\n"
          end
        rescue Aborting
          # do nothing, agent will be dead...
        end
      end

      def get_next_state(state)
        next_state = state.kind_of?(Proc) ? state.call(self) : state
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

    # Base represents innocent-white system agent excluding function for tuple
    # space client.
    class Base < InnocentWhiteObject
      extend StateTransitionSingletonMethod
      include StateTransitionMethod

      def self.inherited(subclass)
        states.each {|st| subclass.define_state st }
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
