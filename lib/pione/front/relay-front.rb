module Pione
  module Front
    class RelayFront < BasicFront
      include TupleSpaceProviderOwner

      def_delegator :@command, :presence_port
      def_delegator :@command, :tuple_space_server

      # Create a new front.
      def initialize(command)
        super(command, Global.relay_front_port_range)
      end

      def presence_notifier
        tuple_space_provider
      end

      def tuple_space_server
        tuple_space_provider.tuple_space_server
      end
    end
  end
end
