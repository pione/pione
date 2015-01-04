module Pione
  module Model
    class TaskWorkerBrokerModel < Rootage::Model
      attr_accessor :task_workers
      attr_accessor :tuple_space
      attr_reader :tuple_space_lock     # lock for tuple space table

      def initialize
        super

        @spawnings = 0                  # number of current spawning task worker
        @task_worker_lock = Monitor.new # lock for task worker table
        @task_workers = Array.new       # known task worker fronts
        @tuple_space_lock = Monitor.new
        @tuple_space = Hash.new         # known tuple space table

        self[:spawn_task_worker] = true
      end

      # Add the tuple space.
      def add_tuple_space(tuple_space)
        uuid = tuple_space.uuid

        # update tuple space table with the id
        @tuple_space_lock.synchronize {@tuple_space[uuid] = tuple_space}
      end

      # Create a task worker for the tuple space. This method returns true if we
      # suceeds to spawn the task worker, or returns false.
      def create_task_worker(tuple_space)
        res = true

        @task_worker_lock.synchronize do
          @spawnings += 1

          # spawn a new process of pione-task-worker command
          if self[:spawn_task_worker]
            # make task worker's parameters
            param = {
              :features => Global.features,
              :tuple_space_id => tuple_space.uuid
            }

            begin
              spawner = Command::PioneTaskWorker.spawn(self, param)
              @task_workers << spawner.child_front
              spawner.when_terminated {delete_task_worker(spawner.child_front)}
            rescue Command::SpawnError => e
              Log::Debug.system("Task worker broker agent failed to spawn a task worker: %s" % e.message)
              res = false
            end
          else
            @task_workers << Agent::TaskWorker.start(tuple_space, Global.expressional_features, @env)
          end

          @spawnings -= 1
        end

        return res
      end

      def delete_task_worker(worker)
        @task_worker_lock.synchronize {@task_workers.delete(worker)}
      end

      # Delete all dead task workers.
      def delete_dead_task_workers
        @task_worker_lock.synchronize do
          @task_workers.delete_if do |worker|
            not(Util.ignore_exception {timeout(1) {worker.ping}})
          end
        end
      end

      # Delete all dead tuple spaces.
      def delete_dead_tuple_spaces
        @tuple_space_lock.synchronize do
          @tuple_space.delete_if do |_, space|
            not(Util.ignore_exception {timeout(1) {space.ping}})
          end
        end
      end

      # Return excess number of task workers belong to the broker.
      def excess_task_workers
        @task_worker_lock.synchronize do
          @task_worker_size - @task_workers.size - @spawnings
        end
      end

      # Get the tuple space.
      def get_tuple_space(tuple_space_id)
        @tuple_space_lock.synchronize {@tuple_space[tuple_space_id]}
      end

      # Return number of task workers the broker manages.
      def quantity
        @task_worker_lock.synchronize {@task_workers.size}
      end

      # Terminate first task worker that satisfies the condition.
      def terminate_task_worker_if(&condition)
        @task_worker_lock.synchronize do
          @task_workers.each do |worker|
            if condition.call(worker)
              worker.terminate
              @task_workers.delete(worker)
              return true
            end
          end
        end
        return false
      end

      # Return known tuple spaces.
      def tuple_spaces
        @tuple_space_lock.synchronize {@tuple_space.values}
      end

      # Update tuple space list.
      def update_tuple_spaces(tuple_spaces)
        @tuple_space_lock.synchronize do
          # clear and update tuple space list
          @tuple_space.clear
          tuple_spaces.each {|tuple_space| add_tuple_space(tuple_space)}

          Log::Debug.system do
            list = @tuple_space.values.map{|space| space.__drburi}
            "Task worker broker has updated tuple space table: %s" % [list]
          end
        end
      end
    end
  end
end
