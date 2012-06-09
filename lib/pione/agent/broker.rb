require 'pione/common'
require 'pione/agent'
require 'pione/agent/task-worker'
require 'pione/agent/broker-task-worker-life-checker'

module Pione
  module Agent
    class Broker < Base
      class Balancer < PioneObject
        def initialize(broker)
          @broker = broker
        end

        def balance
          raise NotImplementedError
        end
      end

      class EasyBalancer < Balancer
        def initialize(broker)
          @broker = broker
        end

        # Balance by killing a task worker in max tuple server.
        def balance
          ratios = calc_resource_ratios
          min = ratios.values.min
          max = ratios.values.max
          min_server = ratios.key(min)
          max_server = ratios.key(max)

          if @broker.excess_task_workers > 0
            create_task_worker(min_server)
          else
            adjust_task_worker(min_server, max_server)
          end
        end

        # Calculate resource ratios of tuple space servers.
        def calc_resource_ratios(revision={})
          ratio = {}
          # make ratio table
          @broker.tuple_space_servers.each do |ts|
            rev = revision.has_key?(ts) ? revision[ts] : 0
            current = ts.current_task_worker_size + rev
            resource = ts.task_worker_resource.to_f
            ratio[ts] = current / resource
          end
          return ratio
        end

        # Create new task worker.
        def create_task_worker(min_server)
          @broker.create_task_worker(min_server)

          if Pione.debug_mode?
            puts "create a new task worker in #{min_server}"
          end
        end

        # Adjust task worker size between tuple space servers.
        def adjust_task_worker(min_server, max_server)
          revision = {min_server => 1, max_server => -1}
          new_ratios = calc_resource_ratios(revision)

          if new_ratios[min_server] < new_ratios[max_server]
            # move worker from max server to min server
            max_workers = @broker.task_workers.select do |worker|
              worker.tuple_space_server == max_server && worker.task_waiting?
            end
            if not(max_workers.empty?)
              max_workers.first.terminate

              # for degging
              if Pione.debug_mode?
                puts "worker #{worker.uuid} moved from #{max_server} to #{min_server}"
              end
            end
          end
        end
      end

      module BrokerMethod
        # Add the tuple space server.
        def add_tuple_space_server(ts_server)
          @tuple_space_servers << ts_server
        end

        # Return excess number of workers belongs to this broker.
        def excess_task_workers
          @task_worker_resource - @task_workers.size
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
          @task_workers << Agent[:task_worker].start(ts)
        end

        # Delete unavilable tuple space servers.
        def check_tuple_space_servers
          @tuple_space_servers.select! do |ts|
            begin
              ts.uuid
              true
            rescue DRb::DRbConnError, Errno::ECONNREFUSED
              false
            end
          end
        end

        # Update tuple space server list.
        def update_tuple_space_servers(tuple_space_servers)
          begin
            del_targets = @tuple_space_servers - tuple_space_servers
            add_targets = tuple_space_servers - @tuple_space_servers
            #return if del_targets.empty? and add_targets.empty?

            # bye
            del_targets.each{|ts_server| bye(ts_server)}
            # hello
            add_targets.each{|ts_server| hello(ts_server)}
            # update
            @tuple_space_servers = tuple_space_servers

            # for debug
            if Pione.debug_mode?
              puts "tuple space servers: #{@tuple_space_servers}"
            end
          rescue DRb::DRbConnError, Errno::ECONNREFUSED
            check_tuple_space_servers
          end
        end
      end

      include BrokerMethod

      set_agent_type :broker

      define_state :count_tuple_space_servers
      define_state :creating_task_worker
      define_state :balancing_task_worker
      define_state :sleeping

      define_state_transition :initialized => :count_tuple_space_servers
      define_state_transition :count_tuple_space_servers => lambda {|agent, res|
        res > 0 ? :balancing_task_worker : :sleeping
      }
      define_state_transition :balancing_task_worker => :sleeping
      define_state_transition :sleeping => :count_tuple_space_servers

      define_exception_handler DRb::DRbConnError => :checking_tuple_space_servers
      define_exception_handler Errno::ECONNREFUSED => :checking_tuple_space_servers

      attr_reader :task_workers
      attr_reader :tuple_space_servers
      attr_reader :task_worker_resource

      # :nodoc:
      def initialize(data={})
        super()
        @task_workers = []
        @tuple_space_servers = []
        @task_worker_resource = data[:task_worker_resource] || 1
        @sleeping_time = data[:sleeping_time] || 1

        # balancer
        @balancer = EasyBalancer.new(self)

        # subagent
        @task_worker_checker = Agent[:broker_task_worker_life_checker].new(self)
      end

      # :nodoc:
      def start
        super
        @task_worker_checker.start
      end

      # Send bye message to tuple space servers when the broker is destroid.
      def finalize
        @tuple_space_servers.each {|ts_server| ts_server.bye }
        super
      end

      private

      def transit_to_initialized
        # start drb service
        DRb.start_service(nil, self)
      end

      def transit_to_count_tuple_space_servers
        @tuple_space_servers.size
      end

      def transit_to_balancing_task_worker
        @balancer.balance
      end

      def transit_to_checking_tuple_space_servers
        check_tuple_space_servers
      end

      # State sleeping.
      def transit_to_sleeping
        sleep 0.3
      end
    end

    set_agent Broker
  end
end
