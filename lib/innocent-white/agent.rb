require 'timeout'
require 'thread'
require 'monitor'
require 'innocent-white/common'
require 'innocent-white/tuple-space-server'

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

    # AgentTypeSingletonMethod provides agent type singleton methods.
    module AgentTypeSingletonMethod
      # Set the agent type.
      def set_agent_type(agent_type)
        @agent_type = agent_type
      end

      # Return the agent type.
      def agent_type
        @agent_type
      end
    end

    # AgentTypeMethod provides agent type methods.
    module AgentTypeMethod
      # Return agent type of the object.
      def agent_type
        self.class.agent_type
      end
    end

    # StateTransitionSingleMethod provides state transition singleton methods.
    module StateTransitionSingletonMethod
      # Define a agent state.
      def define_state(name)
        @states ||= []
        @states << name

        define_method("#{name}?") do
          @__current_state__ == name
        end
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
    end

    # StateTransitionMethod provides state transition methods.
    module StateTransitionMethod
      include Aquarium::DSL

      # Return the current agent's state.
      def current_state
        @__current_state__
      end

      private

      # Set new agent's state.
      def set_current_state(state)
        @__current_state__ = state
        if @__trace_state__
          puts "#{agent_type}(#{uuid}) ==> #{state}"
        end
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

      # Log the state transition.
      advise :before, {
        :methods => :call_transition_method,
        :method_options => [:private]
      } do |jp, obj, *args|
        unless obj.agent_type == :logger
          obj.log do |msg|
            msg.add_record(obj.agent_type, "action", "transit")
            msg.add_record(obj.agent_type, "state", args.first)
            msg.add_record(obj.agent_type, "uuid", obj.uuid)
          end
        end
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
    end

    module AgentRunnerInterface
      # Initialize an agent and start it.
      def start(*args, &b)
        agent = new(*args)
        agent.start
        if block_given?
          begin
            b.call
          ensure
            agent.terminate
          end
        end
        return agent
      end
    end

    # AgentRunnerMethod provides agent's running thread.
    module AgentRunnerMethod
      # State transition thread.
      attr_reader :running_thread

      # Start agent activity.
      def start
        @running_thread = Thread.new { start_running }
        return self
      end

      private

      # Start to transit agent's state.
      # For example, logger should transit initialized, logging, logging, ...
      def start_running
        state_transition_table = self.class.state_transition_table

        begin
          while not(@__aborting__) do
            next_state = state_transition_table[@__current_state__]
            set_current_state(next_state)
            @__result__ = call_transition_method(next_state, *@__result__)
          end
        rescue Aborting
          # do nothing, agent will be dead...
        rescue Object => e
          next_state = exception_handler(e)
          set_current_state(next_state)
          @__result__ = call_transition_method(next_state, e)
          Thread.new { start_running }
        end
      end
    end

    module CommonAgentOperation
      # Terminate the agent.
      def terminate
        # abort the agent when called by other thread
        abort unless @thread == Thread.current
        # transit to terminated
        res = call_transition_method(:terminated)
        # set agent state
        @__current_state__ = :terminated
        # abort if @thread == Thread.current
        return res
      end

      # Send a bye message to the tuple space servers and terminate myself.
      def finalize
        unless current_state == :terminated
          bye
          terminate
        end
      end

      # Abort the agent.
      def abort
        # set variable
        @__aborting__ = true
        if @running_thread
          if @running_thread.alive?
            # raise Aborting exception
            # @running_thread.raise Aborting
            # wait to stop the thread
            @running_thread.join
          end
        end
      end

      # Send a hello message to the tuple space server.
      def hello
        log do |msg|
          msg.add_record(agent_type, "action", "hello")
          msg.add_record(agent_type, "uuid", uuid)
        end
        write(to_agent_tuple)
      end

      # Send a bye message to the tuple space server.
      def bye
        log do |msg|
          msg.add_record(agent_type, "action", "bye")
          msg.add_record(agent_type, "uuid", uuid)
        end
        write(to_bye_tuple)
      end

      # Convert a agent tuple.
      def to_agent_tuple
        Tuple[:agent].new(agent_type: agent_type, uuid: uuid)
      end

      # Convert a bye tuple
      def to_bye_tuple
        Tuple[:bye].new(agent_type: agent_type, uuid: uuid)
      end

      # Notify the agent happened a exception.
      def notify_exception(e)
        # ignore exception because the exception caused tuple server is down...
        Util.ignore_exception do
          write(Tuple[:exception].new(uuid, agent_type, e))
        end
      end

      # Protected take.
      def take(*args)
        tuple = super(*args, &method(:set_current_tuple_entry))
        set_current_tuple_entry(nil)
        return tuple
      end

      # Protected read.
      def read(*args)
        tuple = super(*args, &method(:set_current_tuple_entry))
        set_current_tuple_entry(nil)
        return tuple
      end

      private

      # Return current tuple's entry.
      def current_tuple_entry
        @__current_tuple_entry__
      end

      # Set current operating tuple entry.
      def set_current_tuple_entry(entry)
        @__current_tuple_entry__ = entry
        entry.instance_eval {if @place then def @place.to_s; ""; end; end }
      end

      # Cancel current tuple's entry.
      def cancel_current_tuple_entry
        current_tuple_entry.cancel if current_tuple_entry
      end
    end

    # AgentUtil has various utility methods for agents.
    module AgentUtil
      # Sleep till the agent becomes the state.
      def wait_till(state, sec=5)
        timeout(sec) do
          while not(current_state == state) do
            sleep 0.1
          end
        end
      end

      # Turn on/off state trace mode for debugging.
      def trace_state(mode = true)
        @__trace_state__ = mode
      end
    end

    class Base < InnocentWhiteObject
      include MonitorMixin
      include TupleSpaceServerInterface
      extend AgentTypeSingletonMethod
      include AgentTypeMethod
      extend StateTransitionSingletonMethod
      include StateTransitionMethod
      extend AgentRunnerInterface
      include AgentRunnerMethod
      include CommonAgentOperation
      include AgentUtil

      # Default states.
      define_state :initialized
      define_state :terminated
      define_state :error

      # Initialize agent's state.
      def initialize(ts_server)
        super()
        @__aborting__ = false
        set_tuple_space_server(ts_server)
      end

      # State initialized.
      def transit_to_initialized
        hello
      end

      # State terminated
      def transit_to_terminated
        Util.ignore_exception { bye }
        cancel_current_tuple_entry
        @__aborting__ = true
      end

      # State error
      def transit_to_error(e)
        # print error
        $stderr.puts e
        $stderr.puts e.backtrace
        # exception handling
        notify_exception(e)
        terminate
      end
    end
  end
end
