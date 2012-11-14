module Pione
  module Agent
    class Logger < TupleSpaceClient
      set_agent_type :logger

      def initialize(ts_server, out=$stdout)
        super(ts_server)
        @out = out
        @logs = []
        @last_time = Time.now
      end

      define_state :logging

      define_state_transition :initialized => :logging
      define_state_transition :logging => :write_log
      define_state_transition :write_log => :logging

      define_exception_handler ThreadError => :terminated

      # Sleep till the logger clears logs.
      def wait_to_clear_logs(timespan=0.1)
        while count_tuple(Tuple[:log].any) > 0
          sleep timespan
        end
      end

      private

      # State logging.
      def transit_to_logging
        @logs << take(Tuple[:log].any)
      end

      # Transits to the state +write_log+.
      def transit_to_write_log
        if @logs.size > 0 and Time.now - @last_time > 1
          @logs.sort{|a,b| a.timestamp <=> b.timestamp}.each do |log|
            @out.puts log.message.format
            @out.flush
            @out.sync
          end
          @logs = []
          @last_time = Time.now
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
