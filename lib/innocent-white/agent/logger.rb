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
      define_state :terminated

      define_state_transition :initialized => :logging
      define_state_transition :logging => :logging
      define_exception_handler :terminated

      private

      def transit_to_initialized
        hello
      end

      def transit_to_logging
        log = take(Tuple[:log].any)
        @out.puts "#{log.level}: #{log.message}"
      end

      def transit_to_terminated
        bye
        unless @out == STDOUT
          p @out.closed?
          #@out.close
        end
      end
    end

    set_agent Logger
  end
end
