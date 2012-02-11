require 'rinda/tuplespace'
require 'drb/drb'
require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class Broker < Base
      attr_reader :workers
      attr_reader :tuple_spaces
      attr_reader :resource

      def initialize(data={})
        super()
        @workers = []
        @tuple_spaces = []
        @resource = data[:resource] || 1
      end

      # Start service.
      def start_service
        DRb.start_service(nil, self)
      end

      def add_tuple_space(ts)
        @tuple_spaces << ts
      end

      def run
        start do
          total = 0
          count = {}
          @tuple_spaces.each {|ts| total += ts.worker_resource}
          @tuple_spaces.each do |ts|
            count[ts] = ts.worker_resource - ts.current_worker_size
          end
        end
      end

      def excess_workers
        @resource - @workers.size
      end

      def calc_taple_space_ratio
        total = 0
        count = {}
        @tuple_spaces.each {|ts| total += ts.worker_resource}
        @tuple_spaces.each do |ts|
          count[ts] = ts.worker_resource - ts.current_workers
        end
        return count
      end

      def task_waiting_workers
        @workers.select {|worker| worker.task_waiting?}
      end

      def task_processing_workers
        @workers.select {|worker| worker.task_processing?}
      end

      def dead_workers
        @workers.select {|worker| worker.dead?}
      end

      def create_task_worker(ts)
        @workers << Agent[:task_worker].new(ts)
      end

      def kill_task_worker(worker)
      end

      def sleep_task_worker(worker)
      end

      def change_taple_space(worker)

      end
    end
  end

  Agent[:broker] = Agent::Broker
end
