module Pione
  module Front
    class RelayFront < BasicFront
      attr_reader :presence_port
      attr_reader :tuple_space_server

      # Create a new front.
      def initialize(presence_port, tuple_space)
        super(Global.relay_front_port_range)
        @presence_port = presence_port
        @tuple_space = tuple_space
      end

      def presence_notifier
        tuple_space_provider
      end
    end
  end
end
