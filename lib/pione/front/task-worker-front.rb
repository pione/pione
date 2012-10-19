module Pione
  module Front
    # TaskWorkerFront is a front class for pione-task-worker command.
    class TaskWorkerFront < BasicFront
      attr_reader :agent
      attr_reader :caller_front
      attr_reader :connection_id

      def initialize(caller_front, connection_id)
        @caller_front = caller_front
        @connection_id = connection_id
        tuple_space_server = @caller_front.get_tuple_space_server(@connection_id)
        @agent = Pione::Agent[:task_worker].new(tuple_space_server)

        # connect caller front
        @caller_front.add_task_worker_front(self, @connection_id)
      end

      def terminate
        return if @terminated
        @agent.terminate

        while true
          break if @agent.terminated? and @agent.running_thread.stop?
          sleep 0.1
        end

        # disconnect caller front
        @caller_front.remove_task_worker_front(self, @connection_id)
        @terminated = true
      end
    end
  end
end
