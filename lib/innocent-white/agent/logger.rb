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
      define_state :stopped

      define_state_trasition_table {
        :initialized => :logging,
        :logging => :logging
      }
      catch_exception :stopped

      private

      def transit_to_initialized
        hello
      end

      def transit_to_logging
        log = take(Tuple[:log].any)
        @out.puts "#{log.level}: #{log.message}"
      end

      def transit_to_stopped
        bye
        @out.close if close?
      end
    end

    set_agent Logger
  end
end
