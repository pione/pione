module Pione
  module Front
    # BrokerFront is a front class for pione-broker command.
    class BrokerFront < BasicFront
      def initialize
        super(Global.broker_front_port_range)
      end

      def get_tuple_space(tuple_space_id)
        Global.command.agent.get_tuple_space(tuple_space_id)
      end

      def set_tuple_space_receiver(uri)
        Global.set_tuple_space_receiver_uri(uri)
      end

      def update_tuple_space_list(list)
        Global.command.agent.update_tuple_space_list(list)
      end
    end
  end
end
