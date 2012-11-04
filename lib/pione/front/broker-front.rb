module Pione
  module Front
    # BrokerFront is a front class for pione-broker command.
    class BrokerFront < BasicFront
      include TaskWorkerOwner

      def_delegator :@command, :broker

      # Create a new front.
      def initialize(command)
        super(command, Global.broker_front_port_range)
        initialize_task_worker_owner
      end

      def get_tuple_space_server(connection_id)
        broker.get_tuple_space_server(connection_id)
      end

      # Override the method with adding task worker agent to broker.
      def add_task_worker_front(task_worker_front, connection_id)
        super
        broker.task_workers << task_worker_front.agent
      end

      def set_tuple_space_receiver(uri)
        Global.set_tuple_space_receiver_uri(uri)
      end
    end
  end
end
