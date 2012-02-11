require "uuidtools"

module InnocentWhite
  module Agent
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
