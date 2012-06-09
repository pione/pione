require 'pione/common'

module Pione
  module Agent
    class BrokerTaskWorkerLifeChecker < Base
      set_agent_type :broker_task_worker_life_checker

      define_state :checking_task_worker
      define_state :sleeping

      define_state_transition :initialized => :checking_task_worker
      define_state_transition :checking_task_worker => :sleeping
      define_state_transition :sleeping => :checking_task_worker

      def initialize(broker)
        @broker = broker
        super()
      end

      def transit_to_checking_task_worker
        @broker.task_workers.delete_if {|worker| worker.terminated? }
      end

      def transit_to_sleeping
        sleep 1
      end
    end

    set_agent BrokerTaskWorkerLifeChecker
  end
end
