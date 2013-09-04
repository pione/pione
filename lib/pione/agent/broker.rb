module Pione
  module Agent
    # Broker is an agent for providing task workers to tuple space.
    class Broker < BasicAgent
      set_agent_type :broker, self

      #
      # instance methods
      #

      attr_reader :task_workers # known task workers(agent or task worker front)
      attr_reader :task_worker_resource
      attr_reader :spawnings    # current spawning task worker number

      # @api private
      def initialize(features, option={})
        super()
        @task_workers = Array.new # known task workers(agent or task worker front)
        @tuple_space = Hash.new   # known tuple space table
        @task_worker_resource = option[:task_worker_resource] || 1
        @sleeping_time = option[:sleeping_time] || 1
        @tuple_space_lock = Monitor.new
        @spawnings = 0
        @features = get_features(features) # string form of features

        @option = option
        @option[:spawn_task_worker] = true unless @option.has_key?(:spawn_task_worker)

        # balancer
        @balancer = Global.broker_task_worker_balancer.new(self)
      end

      # Add the tuple space.
      def add_tuple_space(tuple_space)
        # update tuple space table with the id
        @tuple_space_lock.synchronize do
          @tuple_space[tuple_space.uuid] = tuple_space
        end

        # wakeup chain thread if it sleeps
        @chain_threads.list.each do |thread|
          if thread[:agent_state] and thread[:agent_state].current?(:sleep)
            thread.run
          end
        end
      end

      # Get the tuple space.
      def get_tuple_space(tuple_space_id)
        @tuple_space_lock.synchronize do
          @tuple_space[tuple_space_id]
        end
      end

      # Return known tuple spaces.
      def tuple_spaces
        @tuple_space_lock.synchronize {@tuple_space.values}
      end

      # Return excess number of workers belongs to this broker.
      def excess_task_workers
        @task_worker_resource - @task_workers.size - @spawnings
      end

      # Create a task worker for the server.
      def create_task_worker(tuple_space)
        begin
          @spawnings += 1
          if @option[:spawn_task_worker]
            # spawn a new process of pione-task-worker command
            @task_workers << Command::PioneTaskWorker.spawn(@features, tuple_space.uuid)
          else
            # start a new task worker in this process
            @task_workers << Agent::TaskWorker.start(tuple_space, @features_as_sequence)
          end
        ensure
          @spawnings -= 1
        end
      end

      # Delete unavilable tuple space servers.
      def check_tuple_spac
        @tuple_space_lock.synchronize do
          @tuple_space.delete_if do |_, space|
            not(Util.ignore_exception {timeout(1) {space.ping}})
          end
        end
      end

      # Update tuple space list.
      def update_tuple_space_list(tuple_spaces)
        @tuple_space_lock.synchronize do
          @tuple_space = {}
          tuple_spaces.each {|tuple_space| add_tuple_space(tuple_space)}

          timeout(1) do
            msg = "broker's tuple space servers: %s" % [@tuple_space.values]
            ErrorReport.presence_notifier(msg, self, __FILE__, __LINE__)
          end
        end
      rescue Exception
        check_tuple_space
      end

      #
      # agent activities
      #

      define_transition :count_tuple_space
      define_transition :create_task_worker
      define_transition :balance_task_worker
      define_transition :sleep
      define_transition :check_tuple_space
      define_transition :check_task_worker_life

      chain :init => [:count_tuple_space, :check_task_worker_life]
      chain :count_tuple_space => lambda {|agent, res|
        res > 0 ? :balance_task_worker : :sleep
      }
      chain :balance_task_worker => lambda {|agent, rebalance|
        rebalance ? :balance_task_worker : :sleep
      }
      chain :sleep => :count_tuple_space
      chain :check_tuple_space => :count_tuple_space
      chain :check_task_worker_life => :check_task_worker_life

      define_exception_handler Restart => :check_tuple_space

      #
      # transitions
      #

      def transit_to_count_tuple_space
        @tuple_space.size
      end

      def transit_to_balance_task_worker
        @balancer.balance
      end

      def transit_to_check_tuple_space
        check_tuple_space
      end

      def transit_to_sleep
        if @tuple_space.size == 0 or excess_task_workers == 0
          sleep 3
        end
      end

      def transit_to_check_task_worker_life
        @task_workers.delete_if do |worker|
          begin
            timeout(1) { worker.terminated? }
          rescue Exception
            true
          end
        end
        sleep 1
      end

      # Send bye message to tuple spaces when the broker is destroyed.
      def transit_to_terminate
        @tuple_space_lock.synchronize do
          @tuple_space.each do |_, tuple_space|
            Util.ignore_exception {tuple_space.bye}
          end
        end
      end

      #
      # helper methods
      #

      def get_features(features)
        stree = DocumentParser.new.expr.parse(features)
        opt = {package_name: "*feature*", filename: "*feature*"}
        env = Lang::Environment.new
        @features_as_sequence = DocumentTransformer.new.apply(stree, opt).eval!(env)
      rescue Parslet::ParseFailed => e
        puts "invalid parameters: " + str
        Util::ErrorReport.print(e)
        abort
      end
    end

    # TaskWorkerBalancer is a base class for balancing task workers.
    class TaskWorkerBalancer
      # Create a new balancer.
      def initialize(broker)
        @broker = broker
      end

      # Execute task worker balancing. If this method returned true, broker
      # executes rebalance chain with no span. If false, broker sleeps.
      def balance
        raise NotImplementedError
      end
    end

    # EasyBalancer is a balancer by ratios of tuple space and task worker.
    class EasyTaskWorkerBalancer < TaskWorkerBalancer
      # see Balancer.new
      def initialize(broker)
        @broker = broker
      end

      # Balance task worker ratio by creating a new task worker in minimum
      # tuple space or killing a task worker in maximum.
      def balance
        ratios = calc_resource_ratios
        min = ratios.values.min
        max = ratios.values.max
        min_server = ratios.key(min)
        max_server = ratios.key(max)

        return false unless min_server
        return false unless max_server

        if @broker.excess_task_workers > 0 and min_server
          return create_task_worker(min_server)
        else
          return adjust_task_worker(min_server, max_server)
        end
      end

      # Calculate resource ratios of tuple space servers.
      def calc_resource_ratios(revision={})
        ratio = {}
        # make ratio table
        @broker.tuple_spaces.each do |tuple_space|
          Util.ignore_exception do
            rev = revision.has_key?(tuple_space) ? revision[tuple_space] : 0
            current = timeout(1){tuple_space.current_task_worker_size} + rev
            resource = tuple_space.task_worker_resource
            # minimum resource is 1
            resource = 1.0 unless resource > 0
            ratio[tuple_space] = current / resource.to_f
          end
        end
        return ratio
      end

      # Creates a new task worker.
      def create_task_worker(min_server)
        @broker.create_task_worker(min_server)
        return true
      rescue Command::SpawnError => e
        msg = "broker failed to run pione-task-worker command"
        Util::ErrorReport.error(msg, self, e, __FILE__, __LINE__)
      end

      # Adjusts task worker size between tuple space servers.
      def adjust_task_worker(min_server, max_server)
        revision = {min_server => 1, max_server => -1}
        new_ratios = calc_resource_ratios(revision)

        return unless new_ratios.has_key?(min_server)
        return unless new_ratios.has_key?(max_server)

        if new_ratios[min_server] < new_ratios[max_server]
          # kill a task worker for moving worker from max server to min server
          @broker.task_workers.each do |worker|
            if worker.tuple_space_server == max_server && worker.states.any?{|s| s.current?(:take_task)}
              worker.terminate
              @broker.task_workers.delete(worker)
              return true
            end
          end
        end

        return false
      end
    end
  end
end
