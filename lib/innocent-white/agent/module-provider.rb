require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class ModuleProvider
      def initialize(ts_server)
        super(ts_server)
        start_running
      end

      def run
        tuple = @tuple_space_server.take(Tuple[:request_module].any)
        tuple.module_name
      end
    end
  end
end
