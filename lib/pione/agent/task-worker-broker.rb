module Pione
  module Agent
    # `TaskWorkerBroker` is an agent for providing task workers to tuple spaces.
    class TaskWorkerBroker < BasicAgent
      set_agent_type :task_worker_broker, self

      #
      # instance methods
      #

      attr_reader :task_worker_resource # resource size of task worker
      attr_reader :tuple_space_lock     # lock for tuple space table

      def initialize(option={})
        super()

        @task_workers = Array.new # known task worker fronts
        @tuple_space = Hash.new   # known tuple space table
        @task_worker_resource = option[:task_worker_resource] || 1
        @sleeping_time = option[:sleeping_time] || 1
        @spawnings = 0            # number of current spawning task worker
        @tuple_space_lock = Monitor.new
        @task_worker_lock = Monitor.new # lock for task worker table

        @option = option
        @option[:spawn_task_worker] = true unless @option.has_key?(:spawn_task_worker)

        # balancer
        @balancer = Global.task_worker_balancer.new(self)
      end

      # Return number of task workers the broker manages.
      def quantity
        @task_worker_lock.synchronize {@task_workers.size}
      end

      # Add the tuple space.
      def add_tuple_space(tuple_space)
        uuid = tuple_space.uuid

        # update tuple space table with the id
        @tuple_space_lock.synchronize {@tuple_space[uuid] = tuple_space}

        # wakeup chain thread if it sleeps
        @chain_threads.list.each do |thread|
          if thread[:agent_state] and thread[:agent_state].current?(:sleep)
            thread.run
          end
        end
      end

      # Get the tuple space.
      def get_tuple_space(tuple_space_id)
        @tuple_space_lock.synchronize {@tuple_space[tuple_space_id]}
      end

      # Return known tuple spaces.
      def tuple_spaces
        @tuple_space_lock.synchronize {@tuple_space.values}
      end

      # Return excess number of workers belongs to this broker.
      def excess_task_workers
        @task_worker_lock.synchronize do
          @task_worker_resource - @task_workers.size - @spawnings
        end
      end

      # Create a task worker for the server. This method returns true if we
      # suceeded to spawn the task worker, or returns false.
      def create_task_worker(tuple_space)
        res = true

        @task_worker_lock.synchronize do
          @spawnings += 1

          # spawn a new process of pione-task-worker command
          if @option[:spawn_task_worker]
            begin
              spawner = Command::PioneTaskWorker.spawn(Global.features, tuple_space.uuid)
              @task_workers << spawner.child_front
              spawner.when_terminated {delete_task_worker(spawner.child_front)}
            rescue Command::SpawnError => e
              Log::Debug.system("Task worker broker agent failed to spawn a task worker: %e" % e.message)
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

      # Terminate first task worker that satisfies the condition. Return true if 
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

      # Delete unavilable tuple space servers.
      def check_tuple_space
        @tuple_space_lock.synchronize do
          @tuple_space.delete_if do |_, space|
            not(Util.ignore_exception {timeout(1) {space.ping}})
          end
        end
      end

      # Update tuple space list.
      def update_tuple_space_list(tuple_spaces)
        Thread.new do
          begin
            @tuple_space_lock.synchronize do
              # clear and update tuple space list
              @tuple_space = {}
              tuple_spaces.each do |tuple_space|
                Util.ignore_exception {timeout(1) {add_tuple_space(tuple_space)}}
              end

              timeout(1) do
                Log::Debug.presence_notification do
                  "Task worker broker agent updated tuple space table: %s" % [@tuple_space.values.map{|space| space.__drburi}]
                end
              end
            end
          rescue Exception => e
            check_tuple_space
          end
        end
        return true
      end

      #
      # agent activities
      #

      define_transition :count_tuple_space
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
        else
          sleep 1
        end
      end

      def transit_to_check_task_worker_life
        @task_worker_lock.synchronize do
          @task_workers.delete_if do |worker|
            begin
              timeout(1) { worker.ping }
              false
            rescue Exception => e
              true
            end
          end
        end
        sleep 1
      end

      # Send bye message to tuple spaces when the broker is destroyed.
      def transit_to_terminate
        @tuple_space_lock.synchronize do
          @tuple_space.each do |_, tuple_space|
            Util.ignore_exception {timeout(1) {tuple_space.bye}}
          end
        end
      end
    end

    # TaskWorkerBalancer is a base class for balancing task workers.
    class TaskWorkerBalancer
      # Create a new balancer.
      def initialize(task_worker_broker)
        @task_worker_broker = task_worker_broker
      end

      # Execute task worker balancing. If this method returned true, broker
      # executes rebalance chain with no span. If false, broker sleeps a little.
      def balance
        raise NotImplementedError
      end
    end

    # EasyBalancer is a balancer by ratios of tuple space and task worker.
    class EasyTaskWorkerBalancer < TaskWorkerBalancer
      # see Balancer.new
      def initialize(task_worker_broker)
        @task_worker_broker = task_worker_broker
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

        if @task_worker_broker.excess_task_workers > 0 and min_server
          return create_task_worker(min_server)
        else
          return adjust_task_worker(min_server, max_server)
        end
      end

      # Calculate resource ratios of tuple space servers.
      def calc_resource_ratios(revision={})
        ratio = {}
        # make ratio table
        @task_worker_broker.tuple_space_lock.synchronize do
          @task_worker_broker.tuple_spaces.each do |tuple_space|
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

      # Creates a new task worker.
      def create_task_worker(min_server)
        return @task_worker_broker.create_task_worker(min_server)
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
          if @task_worker_broker.terminate_task_worker_if do |worker|
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
