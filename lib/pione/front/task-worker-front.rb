module Pione
  module Front
    # TaskWorkerFront is a front class for pione-task-worker command.
    class TaskWorkerFront < BasicFront
      def_delegator :@command, :caller_front
      def_delegator :@command, :connection_id
      def_delegator :@command, :agent
      def_delegator :@command, :tuple_space_server

      # Create a new front.
      def initialize(command)
        super(command, Global.task_worker_front_port_range)
      end
    end
  end
end
