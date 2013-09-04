module Pione
  module Front
    # BrokerFront is a front class for pione-broker command.
    class BrokerFront < BasicFront
      forward :@command, :broker

      # Create a new front.
      def initialize(command)
        super(command, Global.broker_front_port_range)
        initialize_task_worker_owner
      end

      def get_tuple_space(tuple_space_id)
        @command.broker.get_tuple_space(tuple_space_id)
      end

      def set_tuple_space_receiver(uri)
        Global.set_tuple_space_receiver_uri(uri)
      end
    end
  end
end
