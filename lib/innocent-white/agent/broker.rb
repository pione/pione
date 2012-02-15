require 'rinda/tuplespace'
require 'drb/drb'
require 'innocent-white/agent'
require 'innocent-white/agent/task-worker'

module InnocentWhite
  module Agent
    class Broker < Base
      set_agent_type :broker

      attr_reader :task_workers
      attr_reader :tuple_space_servers
      attr_reader :resource

      def initialize(data={})
        super(nil)
        @task_workers = []
        @tuple_space_servers = []
        @resource = data[:task_worker_resource] || 1
        @sleeping_time = data[:sleeping_time] || 1
        start_running
      end

      # Start service.
      def start_service
        DRb.start_service(nil, self)
      end

      def add_tuple_space_server(ts_server)
        @tuple_space_servers << ts_server
      end

      def excess_workers
        @resource - @task_workers.size
      end

      # Return task wainting workers.
      def task_waiting_workers
        @task_workers.select {|worker| worker.status.task_waiting?}
      end

      # Return task processing workers.
      def task_processing_workers
        @task_workers.select {|worker| worker.status.task_processing?}
      end

      # Return terminated task workers.
      def terminated_task_workers
        @task_workers.select {|worker| worker.status.terminated?}
      end

      # Create a task worker for the server.
      def create_task_worker(ts)
        @task_workers << Agent[:task_worker].new(ts)
      end

      def terminate_task_worker(worker)
      end

      def stop_task_worker(worker)
      end

      def change_taple_space(worker)

      end

      # Update tuple space server list.
      def update_tuple_space_servers(tuple_space_servers)
        begin
          # bye
          (@tuple_space_servers - tuple_space_servers).each do |ts_server|
            bye(ts_server)
          end
          # hello
          (tuple_space_servers - @tuple_space_servers).each do |ts_server|
            hello(ts_server)
          end
          # update
          @tuple_space_servers = tuple_space_servers
          p @tuple_space_servers
        rescue DRb::DRbConnError
          check_tuple_space_server
        end
      end

      private

      def run
        begin
          if @tuple_space_servers.size > 0
            ratios = calc_resource_ratios
            min = ratios.values.min
            max = ratios.values.max
            min_server = ratios.key(min)
            max_server = ratios.key(max)

            if excess_workers > 0
              create_task_worker(min_server)
            else
              revision = {min_server => 1, max_server => -1}
              new_ratios = calc_resource_ratios(revision)
              if new_ratios[min_server] < new_ratios[max_server]
                # move worker from max server to min server
                max_workers = task_workers.select do |worker|
                  worker.tuple_space_server == max_server
                end
                waitings = max_workers.select do |worker|
                  worker.status.task_waiting?
                end
                worker = not(waitings.empty?) ? waitings.first : workers.first
                worker.move_tuple_space_server(min_server)
              end
            end
          end
        rescue DRb::DRbConnError
          check_tuple_space_server
        end

        sleep @sleeping_time
      end

      # Calculate resource ratios of tuple space servers.
      def calc_resource_ratios(revision={})
        ratio = {}
        # make ratio table
        @tuple_space_servers.each do |ts|
          rev = revision.has_key?(ts) ? revision[ts] : 0
          current = ts.current_task_worker_size + rev
          resource = ts.task_worker_resource.to_f
          ratio[ts] = current / resource
        end
        return ratio
      end

      def check_tuple_space_server
        @tuple_space_servers.select! do |ts|
          begin
            ts.uuid
            true
          rescue DRb::DRbConnError
            false
          end
        end
      end

    end

    set_agent Broker
  end
end
