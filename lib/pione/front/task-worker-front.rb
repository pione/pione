module Pione
  module Front
    # TaskWorkerFront is a front interface for pione-task-worker command.
    class TaskWorkerFront < BasicFront
      def initialize(cmd)
        super(cmd, Global.task_worker_front_port_range)
      end
    end
  end
end
