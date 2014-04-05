module Pione
  module Front
    # `TaskWorkerBrokerFront` is a front interface for
    # `pione-task-worker-broker` command.
    class TaskWorkerBrokerFront < BasicFront
      # this receives notification messages
      include NotificationRecipientInterface

      def initialize(cmd)
        super(cmd, Global.task_worker_broker_front_port_range)
        set_recipient(Notification::TaskWorkerBrokerRecipient.new(cmd.model, uri, Global.notification_listener))
      end

      def get_tuple_space(tuple_space_id)
        @cmd.model.get_tuple_space(tuple_space_id)
      end
    end
  end
end
