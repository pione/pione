module Pione
  module Agent
    # Logger is an agent for logging in tuple space.
    class Logger < TupleSpaceClient
      set_agent_type :logger

      def initialize(tuple_space_server, out=$stdout)
        super(tuple_space_server)
        @out = out
        @logs = []
      end

      define_state :take
      define_state :store

      define_state_transition :initialized => :take
      define_state_transition :take => :store
      define_state_transition :store => :take

      define_exception_handler Exception => :terminated

      # Sleeps till the logger clears logs.
      # @param [Float]
      #   timespan for clearing logs
      def wait_to_clear_logs(timespan=0.1)
        while count_tuple(Tuple[:log].any) > 0 || @logs.size > 0
          sleep timespan
        end
      end

      private

      # Transits to the state +take_log+.
      def transit_to_take
        timeout(2) do
          @logs << take(Tuple[:log].any)
        end
      rescue TimeoutError
        # ignore
      end

      # Transits to the state +store+.
      def transit_to_store
        unless @logs.empty?
          @logs.sort{|a,b| a.timestamp <=> b.timestamp}.each do |log|
            @out.puts log.message.format
            @out.flush
            @out.sync
          end
          @logs = []
        end
      end

      # State terminated.
      def transit_to_terminated
        super
        unless @out == STDOUT
          Util.ignore_exception { @out.close }
        end
      end
    end

    set_agent Logger
  end
end
