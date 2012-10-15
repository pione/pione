module Pione
  module Front
    class TaskWorkerFront < BaseFront
      attr_reader :agent
      attr_reader :connection_id

      def initialize(caller_front, connection_id)
        @caller_front = caller_front
        @connection_id = connection_id
        tuple_space_server = @caller_front.get_tuple_space_server(@connection_id)
        @agent = Pione::Agent[:task_worker].new(tuple_space_server)

        # connect caller front
        @caller_front.add_task_worker_front(self, @connection_id)
      end

      def start
        # start task worker activity
        @agent.start

        # wait...
        @agent.running_thread.join

        # terminate
        terminate
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
