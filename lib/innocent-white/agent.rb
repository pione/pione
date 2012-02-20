require 'innocent-white/util'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'
require 'innocent-white/innocent-white-object'

module InnocentWhite
  class AgentStatus
    def self.define_state(state)
      # define self.#{state} by singleton class
      singleton_class = class << self; self; end
      singleton_class.instance_eval do
        define_method(state){new(state)}
      end
      # define accessors
      define_method(state){@state = state}
      define_method("#{state}?"){state === self}
      # add state list
      @state_list = [] if @state_list.nil?
      @state_list << state
    end

    def self.define_sub_state(parent, child)
      if state_list.include?(parent)
        define_state(child)
        @rel = {} if @rel.nil?
        @rel[child] = parent
      else
        raise ArgumentError
      end
    end

    def self.state_list
      list = (@state_list || [] )
      superclass.respond_to?(:state_list) ? superclass.state_list + list : list
    end

    define_state :initialized
    define_state :running
    define_state :stopped
    define_state :terminated

    attr_reader :state

    def initialize(state = :initialized)
      if self.class.state_list.include?(state)
        @state = state
      else
        raise ArgumentError
      end
    end

    def parent
      state = @state
      self.class.module_eval {begin @rel[state] rescue nil end}
    end

    def parent?(other)
      parent ? parent == other : false
    end

    def ancestor?(target)
      if parent
        parent?(target) || self.class.new(parent).ancestor?(target)
      else
        false
      end
    end

    def ==(other)
      if other.kind_of?(AgentStatus)
        @state == other.state
      else
        @state == other
      end
    end

    alias :eql? :==

    def hash
      @state.hash
    end

    def ===(other)
      other = other.state if other.kind_of?(AgentStatus)
      @state == other || ancestor?(other)
    end
  end

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

    class Base < InnocentWhiteObject
      include TupleSpaceServerInterface

      # -- class methods --

      # Set the agent type.
      def self.set_agent_type(agent_type)
        @agent_type = agent_type
      end

      # Return the agent type.
      def self.agent_type
        @agent_type
      end

      # Set the agent status class.
      def self.set_status_class(klass)
        @status_class = klass
      end

      # Return the agent status class.
      def self.status_class
        @status_class || AgentStatus
      end

      def self.define_state(name)
        @states ||= []
        @states << name

        define_method("#{name}?") do
          @__current_state__ == name
        end
      end

      def self.state_transition_table
        @__state_transition_table__ ||= {nil => :initialized}
      end

      def self.exception_handler
        @__exception_handler__ ||= :terminated
      end

      def self.define_state_transition(data)
        table = state_transition_table
        table.merge!(data)
      end

      def self.define_exception_handler(state)
        @__exception_handler__ = state
      end

      # -- instance methods --

      attr_reader :status
      attr_reader :thread
      attr_reader :agent_type

      # Initialize agent's state.
      def initialize(ts_server)
        @status = self.class.status_class.initialized
        @__runnable__ = nil
        set_tuple_space_server(ts_server)
        @__next_tuple_space_server__ = nil

        start_running
      end

      def terminate
        @running_thread.kill unless @running_thread == Thread.current
        res = call_transition_method(:terminated)
        @__current_state__ = :terminated
        @running_thread.kill
        return res
      end

      # Send bye message to the tuple space servers.
      def finalize
        bye
      end

      # Return agent type of the object.
      def agent_type
        self.class.agent_type
      end

      # Hello, tuple space server.
      def hello
        log(:debug, "hello, I am #{uuid}")
        write(to_agent_tuple)
      end

      # Bye, tuple space server.
      def bye
        log(:debug, "bye, I am #{uuid}")
        write(to_bye_tuple)
      end

      # Stop the agent.
      def stop
        @__runnable__ = false
        Thread.new do
          @thread.join
          @status.stopped
        end
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

      def log(level, msg)
        super(level, "#{agent_type}: #{msg}")
      end

      private

      def start_running
        state_transition_table = self.class.state_transition_table
        exception_handler = self.class.exception_handler

        @running_thread = Thread.new do
          begin
            loop do
              next_state = state_transition_table[@__current_state__]
              @__result__ = call_transition_method(next_state, @__result__)
              @__current_state__ = next_state
            end
          rescue Exception => e
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
        _args = args[0...(arity-1)]
        method.call(*_args)
      end

      # Convert a agent tuple.
      def to_agent_tuple
        Tuple[:agent].new(agent_type: agent_type, uuid: uuid)
      end

      # Convert a bye tuple
      def to_bye_tuple
        Tuple[:bye].new(agent_type: agent_type, uuid: uuid)
      end

    end
  end
end

class Symbol
  alias :__eq3_orig__ :===

  def ===(other)
    if other.kind_of?(InnocentWhite::AgentStatus)
      other === self
    else
      __eq3_orig__(other)
    end
  end
end
