require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class Logger < Base
      set_agent_type :logger
      
      def initialize(ts_server, out=$stdout)
        super(ts_server)
        @out = out
        start_running
      end

      def run
        req = Tuple[:log].any
        log = @tuple_space_server.take(req).to_tuple
        @out.puts "#{log.level}: #{log.message}"
      end
    end

    set_agent Logger
  end
end
