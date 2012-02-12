require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class TaskWorker < Base
      class TaskWorkerStatus < AgentStatus
        define_sub_state :running, :task_waiting
        define_sub_state :running, :task_processing
      end

      set_status_class TaskWorkerStatus
      set_agent_type :task_worker

      attr_accessor :tuple_space_server

      def initialize(ts_server)
        super(ts_server)
        hello()
        unless start_running()
          raise
        end
      end

      # Start running for processing tasks
      def run
        @status.task_waiting
        process_task(@tuple_space_server.take(Tuple[:task].any))
      end

      private

      def process_task(task)
        @status.task_processing
        # dummy
      end
    end

    set_agent TaskWorker
  end
end
