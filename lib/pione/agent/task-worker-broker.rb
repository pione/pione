module Pione
  module Agent
    # `TaskWorkerBroker` is an agent for providing task workers to tuple spaces.
    class TaskWorkerBroker < BasicAgent
      set_agent_type :task_worker_broker, self

      #
      # instance methods
      #

      def initialize(model)
        super()
        @model = model
        @provider = Global.task_worker_provider.new(model)
      end

      #
      # activity definitions
      #

      define_transition :count_tuple_space
      define_transition :provide_task_worker
      define_transition :sleep
      define_transition :check_tuple_space
      define_transition :check_task_worker_life

      chain :init => [:count_tuple_space, :check_task_worker_life]
      chain :count_tuple_space => lambda {|agent, res|
        res > 0 ? :provide_task_worker : :sleep
      }
      chain :provide_task_worker => lambda {|agent, rebalance|
        rebalance ? :provide_task_worker : :sleep
      }
      chain :sleep => :count_tuple_space
      chain :check_tuple_space => :count_tuple_space
      chain :check_task_worker_life => :check_task_worker_life

      define_exception_handler Restart => :check_tuple_space

      #
      # transitions
      #

      def transit_to_init
        Log::SystemLog.info "Task worker broker starts the activity."
      end

      def transit_to_count_tuple_space
        @model.tuple_space.size
      end

      def transit_to_provide_task_worker
        @provider.provide
      end

      def transit_to_check_tuple_space
        @model.check_tuple_space
      end

      def transit_to_sleep
        if @model.tuple_space.size == 0 or @model.excess_task_workers == 0
          sleep Global.task_worker_broker_long_sleep_time
        else
          sleep Global.task_worker_broker_short_sleep_time
        end
      end

      def transit_to_check_task_worker_life
        @model.delete_dead_task_workers
        sleep Global.task_worker_broker_short_sleep_time
      end

      # Send bye messages to tuple spaces when the agent is terminated.
      def transit_to_terminate
        @model.tuple_space_lock.synchronize do
          @model.tuple_spaces.each do |tuple_space|
            Util.ignore_exception {timeout(1) {tuple_space.bye}}
          end
        end
        Log::SystemLog.info "Task worker broker ends the activity."
      end
    end
  end
end
