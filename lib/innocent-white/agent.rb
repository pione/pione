require 'timeout'
require 'thread'
require 'monitor'
require 'innocent-white'
require 'innocent-white/common'
require 'innocent-white/tuple'
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

    class Base < InnocentWhiteObject
      include MonitorMixin
      include TupleSpaceServerInterface

      # -- class --

      # Set the agent type.
      def self.set_agent_type(agent_type)
        @agent_type = agent_type
      end

      # Return the agent type.
      def self.agent_type
        @agent_type
      end

      # Define a state.
      def self.define_state(name)
        @states ||= []
        @states << name

        define_method("#{name}?") do
          @__current_state__ == name
        end
      end

      # Return state transition table.
      def self.state_transition_table
        @__state_transition_table__ ||= {nil => :initialized}
      end

      # Return exception handler.
      def self.exception_handler
        @__exception_handler__ ||= :terminated
      end

      # Define a state transition.
      def self.define_state_transition(data)
        table = state_transition_table
        table.merge!(data)
      end

      # Define exception handler.
      def self.define_exception_handler(state)
        @__exception_handler__ = state
      end

      # Initialize an agent and start it.
      def self.start(*args)
        agent = new(*args)
        agent.start
        return agent
      end

      # -- instance --

      attr_reader :thread
      attr_reader :agent_type

      # Initialize agent's state.
      def initialize(ts_server)
        super()
        @running_thread = nil
        @__aborting__ = false
        set_tuple_space_server(ts_server)
      end

      # Start agent activity.
      def start
        start_running
        return self
      end

      # Return current state.
      def current_state
        @__current_state__
      end

      # Terminate the agent.
      def terminate
        abort unless @running_thread == Thread.current
        res = call_transition_method(:terminated)
        @__current_state__ = :terminated
        abort if @running_thread == Thread.current
        return res
      end

      # Send a bye message to the tuple space servers.
      def finalize
        bye
      end

      # Return agent type of the object.
      def agent_type
        self.class.agent_type
      end

      # Hello, tuple space server.
      def hello
        log(:debug, "hello, I am #{uuid}") if InnocentWhite.debug_mode?
        write(to_agent_tuple)
      end

      # Bye, tuple space server.
      def bye
        # log(:debug, "bye, I am #{uuid}") if InnocentWhite.debug_mode?
        write(to_bye_tuple)
      end

      # Notify the agent happened a exception.
      def notify_exception(e)
        # ignore exception because the exception caused tuple server is down...
        Util.ignore_exception { write(Tuple[:exception].new(uuid, agent_type, e)) }
      end

      # Kill current running thread and move to tuple space.
      def move_tuple_space_server(tuple_space_server)
        bye()
        @__next_tuple_space_server__ = tuple_space_server
        # kill running thread and wait to exit
        @thread.kill
        @thread.join
        # restart running thread
        start_running
        while not(@__next_tuple_space_server__.nil?) do
          sleep 0.01
        end
      end

      # Send a log message.
      def log(level, msg)
        super(level, "#{agent_type} on #{Util.hostname}: #{msg}")
      end

      # Sleep till the agent becomes the state.
      def wait_till(state, sec=5)
        timeout(sec) do
          while not(current_state == state) do
            sleep 0.1
          end
        end
      end

      # Convert a agent tuple.
      def to_agent_tuple
        Tuple[:agent].new(agent_type: agent_type, uuid: uuid)
      end

      # Convert a bye tuple
      def to_bye_tuple
        Tuple[:bye].new(agent_type: agent_type, uuid: uuid)
      end

      private

      # Start to transit agent's state.
      def start_running
        # Return if the agent is running already.
        return unless @running_thread.nil?

        state_transition_table = self.class.state_transition_table
        exception_handler = self.class.exception_handler

        @running_thread = Thread.new do
          begin
            while not(@__aborting__) do
              next_state = state_transition_table[@__current_state__]
              set_current_state(next_state)
              @__result__ = call_transition_method(next_state, *@__result__)
            end
          rescue Aborting
            # do nothing
          rescue Object => e
            call_transition_method(exception_handler, e)
          end
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

      # Set current state.
      def set_current_state(state)
        @__current_state__ = state
      end

      def abort
        @__aborting__ = true
        if @running_thread.alive?
          @running_thread.raise Aborting
          @running_thread.join
        end
      end
    end
  end
end
