module Pione
  module Front
    # BrokerFront is a front class for pione-broker command.
    class BrokerFront < BasicFront
      include TaskWorkerOwner

      def_delegator :@command, :broker

      # Create a new front.
      def initialize(command)
        super(command, nil)
        initialize_task_worker_owner
      end

      def get_tuple_space_server(connection_id)
        broker.get_tuple_space_server(connection_id)
      end

      def add_task_worker(task_worker)
        broker.add_task_worker(task_worker)
      end

      def set_tuple_space_receiver(uri)
        Global.set_tuple_space_receiver_uri(uri)
      end
    end
  end
end
