require 'innocent-white'
require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class Logger < Base
      set_agent_type :logger

      def initialize(ts_server, out=$stdout)
        super(ts_server)
        @out = out
      end

      define_state :initialized
      define_state :logging
      define_state :error
      define_state :terminated

      define_state_transition :initialized => :logging
      define_state_transition :logging => :logging
      define_exception_handler :error

      # Sleep till the logger clears logs.
      def wait_to_clear_logs(timespan=0.1)
        while count_tuple(Tuple[:log].any) > 0
          sleep timespan
        end
      end

      private

      # State initialized.
      def transit_to_initialized
        hello
      end

      # State logging.
      def transit_to_logging
        log = take(Tuple[:log].any)
        @out.puts "#{log.level}: #{log.message}"
      end

      # State error.
      def transit_to_error(e)
        notify_exception(e)
        terminate
      end

      # State terminated.
      def transit_to_terminated
        Util.ignore_exception { bye }
        unless @out == STDOUT
          Util.ignore_exception { @out.close }
        end
      end
    end

    set_agent Logger
  end
end
