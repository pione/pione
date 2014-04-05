module Pione
  module TaskWorkerBroker
    # `EasyProvider` is a task worker provider by blancing ratios of tuple space
    # and task worker.
    class EasyProvider < BasicProvider
      # Balance task worker ratio by creating a new task worker in minimum
      # tuple space or killing a task worker in maximum.
      def provide
        ratios = calc_resource_ratios
        min = ratios.values.min
        max = ratios.values.max
        min_server = ratios.key(min)
        max_server = ratios.key(max)

        return false unless min_server
        return false unless max_server

        if @model.excess_task_workers > 0 and min_server
          return @model.create_task_worker(min_server)
        else
          return adjust_task_worker(min_server, max_server)
        end
      end

      # Calculate resource ratios of tuple space servers.
      def calc_resource_ratios(revision={})
        ratio = {}
        # make ratio table
        @model.tuple_space_lock.synchronize do
          @model.tuple_spaces.each do |tuple_space|
            rev = revision.has_key?(tuple_space) ? revision[tuple_space] : 0
            current = timeout(1){tuple_space.current_task_worker_size} + rev
            resource = tuple_space.task_worker_resource
            # minimum resource is 1
            resource = 1 unless resource > 0
            ratio[tuple_space] = current / resource.to_f
          end
        end
        return ratio
      end

      # Adjusts task worker size between tuple space servers.
      def adjust_task_worker(min_server, max_server)
        revision = {min_server => 1, max_server => -1}
        new_ratios = calc_resource_ratios(revision)

        # failed to calculate tuple space ratio
        return unless new_ratios.has_key?(min_server)
        return unless new_ratios.has_key?(max_server)

        # kill a task worker for moving worker from max server to min server
        if new_ratios[min_server] < new_ratios[max_server]
          if @model.terminate_task_worker_if do |worker|
            worker.tuple_space == max_server && worker.states.any?{|s| s.current?(:take_task)}
          end
            return true
          end
        end

        # failed to adjust task workers
        return false
      end
    end
  end
end
