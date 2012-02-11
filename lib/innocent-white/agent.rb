module InnocentWhite
  module Agent
    TABLE = Hash.new

    # Return a class for agent type.
    def self.[](type)
      TABLE[type]
    end

    # Define a agent of the type.
    def self.define_agent(type, klass)
      TABLE[type] = klass
    end

    class Base
      attr_reader :state
      attr_reader :runnable
      attr_reader :thread
      attr_reader :agent_id

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

      def change_tuplespace(tuplespace)
        @next_tuplespace = tuplespace
      end

      def to_agent_tuple
        Tuple[:agent].new(agent_id: @agent_id)
      end

      private

      # Start the action.
      def start(&b)
        @thread = Thread.new do
          # start
          @state = :running
          @runnable = true

          # task loop
          white @runnable do
            # tuple space
            if @next_tuplespace
              ts = @next_tuplespace
              @next_tuplespace = nil
              @tuple_space = ts
            end
            # do task
            eval b
          end

          # stop
          @state = :stop
          @runnable = nil
        end
      end

    end
  end
end
