module Pione
  module Agent
    class Broker < BasicAgent
      # Balancer is a base class for balancing task workers.
      class Balancer < PioneObject
        # Create a new balancer.
        def initialize(broker)
          @broker = broker
        end

        def balance
          raise NotImplementedError
        end
      end

      # EasyBalancer is a balancer by ratios of tuple space server and task worker.
      class EasyBalancer < Balancer
        # see Balancer.new
        def initialize(broker)
          @broker = broker
        end

        # Balances by killing a task worker in max tuple server.
        def balance
          ratios = calc_resource_ratios
          min = ratios.values.min
          max = ratios.values.max
          min_server = ratios.key(min)
          max_server = ratios.key(max)

          return unless min_server
          return unless max_server

          if @broker.excess_task_workers > 0 and min_server
            create_task_worker(min_server)
          else
            adjust_task_worker(min_server, max_server)
          end
        end

        # Calculates resource ratios of tuple space servers.
        def calc_resource_ratios(revision={})
          ratio = {}
          # make ratio table
          @broker.tuple_space_servers.each do |ts|
            begin
              rev = revision.has_key?(ts) ? revision[ts] : 0
              current = timeout(1){ts.current_task_worker_size} + rev
              resource = ts.task_worker_resource
              # minimum resource is 1
              resource = 1.0 unless resource > 0
              ratio[ts] = current / resource.to_f
            rescue Exception
              # ignore
            end
          end
          return ratio
        end

        # Creates a new task worker.
        def create_task_worker(min_server)
          @broker.create_task_worker(min_server)

          if Pione.debug_mode?
            puts "create a new task worker in #{min_server}"
          end
        end

        # Adjusts task worker size between tuple space servers.
        def adjust_task_worker(min_server, max_server)
          revision = {min_server => 1, max_server => -1}
          new_ratios = calc_resource_ratios(revision)

          return unless new_ratios.has_key?(min_server)
          return unless new_ratios.has_key?(max_server)

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
        # Adds the tuple space server.
        def add_tuple_space_server(tuple_space_server)
          @tuple_space_server_lock.synchronize do
            @tuple_space_servers << tuple_space_server
          end
        end

        # Gets a tuple space server by connection id.
        def get_tuple_space_server(connection_id)
          @assignment_table[connection_id]
        end

        # Return excess number of workers belongs to this broker.
        def excess_task_workers
          @task_worker_resource - @task_workers.size - @spawnings
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
        def create_task_worker(tuple_space_server)
          connection_id = Util.generate_uuid
          @assignment_table[connection_id] = tuple_space_server
          Thread.new do
            begin
              @spawnings += 1
              Agent[:task_worker].spawn(Global.front, connection_id, @features)
            ensure
              @spawnings -= 1
            end
          end
        end

        # Deletes unavilable tuple space servers.
        def check_tuple_space_servers
          @tuple_space_server_lock.synchronize do
            @tuple_space_servers.select! do |ts|
              begin
                timeout(1) { ts.ping }
              rescue Exception
                false
              end
            end
          end
        end

        # Update tuple space server list.
        def update_tuple_space_servers(tuple_space_servers)
          @tuple_space_server_lock.synchronize do
            del_targets = @tuple_space_servers - tuple_space_servers
            add_targets = tuple_space_servers - @tuple_space_servers

            # bye
            #del_targets.each do |ts_server|
            #  ts_server.write(Tuple[:bye].new(agent_type: agent_type, uuid: uuid))
            #end
            # hello
            #add_targets.each do |ts_server|
            #  ts_server.write(Tuple[:agent].new(agent_type: agent_type, uuid: uuid))
            #end

            # update
            @tuple_space_servers = tuple_space_servers

            if Global.show_presence_notifier
              timeout(1) do
                puts "broker's tuple space servers: %s" % [@tuple_space_servers]
              end
            end
          end
        rescue Exception
          check_tuple_space_servers
        end
      end

      include BrokerMethod

      set_agent_type :broker

      define_state :count_tuple_space_servers
      define_state :creating_task_worker
      define_state :balancing_task_worker
      define_state :sleeping
      define_state :checking_tuple_space_servers

      define_state_transition :initialized => :count_tuple_space_servers
      define_state_transition :count_tuple_space_servers => lambda {|agent, res|
        res > 0 ? :balancing_task_worker : :sleeping
      }
      define_state_transition :balancing_task_worker => :sleeping
      define_state_transition :sleeping => :count_tuple_space_servers
      define_state_transition :checking_tuple_space_servers => :count_tuple_space_servers

      define_exception_handler Exception => :checking_tuple_space_servers

      attr_accessor :task_workers
      attr_reader :tuple_space_servers
      attr_reader :task_worker_resource

      # current spawning task worker number
      attr_reader :spawnings

      # @api private
      def initialize(features, data={})
        super()
        @task_workers = []
        @tuple_space_servers = []
        @task_worker_resource = data[:task_worker_resource] || 1
        @sleeping_time = data[:sleeping_time] || 1
        @assignment_table = {}
        @tuple_space_server_lock = Mutex.new
        @spawnings = 0
        @features = features

        # balancer
        @balancer = EasyBalancer.new(self)

        # start agents
        @task_worker_checker = Agent::TrivialRoutineWorker.new(
          Proc.new do
            @task_workers.delete_if do |worker|
              begin
                timeout(3) { worker.terminated? }
              rescue Exception
                true
              end
            end
            sleep 1
          end
        )
      end

      # @api private
      def start
        super
        @task_worker_checker.start
      end

      # Sends bye message to tuple space servers when the broker is destroyed.
      def finalize
        @tuple_space_server_lock.synchronize do
          @tuple_space_servers.each do |ts_server|
            begin
              ts_server.bye
            rescue Exception
              # ignore
            end
          end
        end
        super
      end

      private

      # @api private
      def transit_to_initialized
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

      # Transits to the state +sleeping+.
      def transit_to_sleeping
        if @tuple_space_servers.size == 0 or excess_task_workers == 0
          sleep 1
        end
      end
    end

    set_agent Broker
  end
end
