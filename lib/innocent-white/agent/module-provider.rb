require 'innocent-white/agent'
require 'innocent-white/process-handler'

module InnocentWhite
  module Agent
    class ModuleProvider < Base
      set_agent_type :module_provider

      def initialize(ts_server)
        super(ts_server)
        @table = {}
        hello()
        start_running()
      end

      define_state :initialized
      define_state :request_waiting
      define_state :stopped

      def add_module(path, content)
        raise ArgumentError unless content.ancestors.include?(ProcessHandler::BaseProcess)
        @table[path] = content
      end

      def known_module?(path)
        @table.has_key?(path)
      end

      def run
        tuple = take(Tuple[:request_module].any)
        out = Tuple[:module].new(path: tuple.path)
        if known_module?(tuple.path)
          out.status = :known
          out.content = @table[tuple.path]
        else
          out.status = :unknown
        end
        write(out)
      end
    end

    set_agent ModuleProvider
  end
end
