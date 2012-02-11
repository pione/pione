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

    class Base
      # -- class methods --

      # Set the agent type.
      def self.set_agent_type(agent_type)
        @agent_type = agent_type
      end

      # Return the agent type.
      def self.agent_type
        @agent_type
      end

      # -- instance methods --

      attr_reader :state
      attr_reader :runnable
      attr_reader :thread
      attr_reader :agent_id
      attr_reader :agent_type

      # Initialize agent's state.
      def initialize
        @state = :stop
        @runnable = nil
        @agent_id = UUIDTools::UUID.random_create.to_s
      end

      # Stop the agent.
      def stop
        @runnable = false
      end

      # Change tuple space.
      def change_tuple_space(tuple_space)
        @next_tuple_space = tuple_space
      end

      # Convert a agent tuple.
      def to_agent_tuple
        Tuple[:agent].new(agent_type: self.class.agent_type,
                          agent_id: @agent_id)
      end

      private

      # Start the action.
      def start(&b)
        @thread = Thread.new do
          # start
          @state = :running
          @runnable = true

          # task loop
          while @runnable do
            # tuple space
            if @next_tuplespace
              ts = @next_tuplespace
              @next_tuplespace = nil
              @tuple_space = ts
            end
            # do task
            b.call
          end

          # stop
          @state = :stop
          @runnable = nil
        end
      end

    end
  end
end
