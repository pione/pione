require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class TaskWorker < Base
      set_agent_type :task_worker

      attr_accessor :tuple_space_server

      def initialize(ts_server)
        super()
        @tuple_space_server = ts_server
        hello()
        run()
      end

      def hello
        @tuple_space_server.write(self.to_agent_tuple)
      end

      # Start running for processing tasks
      def run
        start do
          work(@tuple_space_server.take(Tuple[:task].any))
        end
      end

      private

      def work(task)
        # dummy
      end
    end

    set_agent TaskWorker
  end
end
