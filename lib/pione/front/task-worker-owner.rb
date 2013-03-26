module Pione
  module Front
    module TaskWorkerOwner
      attr_reader :task_worker_fronts
      attr_reader :task_worker_front_connection_id

      def get_tuple_space_server
        raise NotImplementedError
      end

      def add_task_worker_front(task_worker_front, connection_id)
        @task_worker_fronts << task_worker_front
        @task_worker_front_connection_id << connection_id
      end

      def remove_task_worker_front(task_worker_front, connection_id)
        @task_worker_fronts.delete(task_worker_front)
        @task_worker_front_connection_id.delete(connection_id)
      end

      def terminate
        terminate_task_worker_fronts
        super
      end

      private

      def initialize_task_worker_owner
        @task_worker_fronts = []
        @task_worker_front_connection_id = []
      end

      def terminate_task_worker_fronts
        @task_worker_fronts.each do |front|
          begin
            front.terminate
          rescue
          end
        end
      end
    end
  end
end
