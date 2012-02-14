require 'innocent-white/agent'
require 'innocent-white/process-handler'

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
        process_task(@tuple_space_server.take(Tuple[:task].any).to_tuple)
      end

      private

      def process_task(task)
        @status.task_processing

        path = task.name
        inputs = task.inputs
        output = task
        task_id = task.task_id

        # excute the process
        mod = Tuple[:module].new(path: task.name, statue: :known)
        process_class = @tuple_space_server.read(mod).to_tuple
        handler = process_class.content.new(inputs)
        result = handler.execute

        # output data
        # FIXME: handle raw data only now
        data = Tuple[:data].new(data_type: raw, name: handler.outputs.first)

        # finished
        finished = Tuple[:finished].new(task_id: task_id, status: :succeeded)
        @tuple_space_server.write(finished)
      end
    end

    set_agent TaskWorker
  end
end
