require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class TaskWorker < Base
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
          task = @tuple_space_server.take(Tuple[:task].any)
          work task
        end
      end

      private

      def work(task)
        # dummy
      end
    end

    define_agent(:task_worker, TaskWorker)
  end
end
