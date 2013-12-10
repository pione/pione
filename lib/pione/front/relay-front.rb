module Pione
  module Front
    class RelayFront < BasicFront
      attr_reader :notification_port
      attr_reader :tuple_space_server

      # Create a new front.
      def initialize(notification_port, tuple_space)
        super(Global.relay_front_port_range)
        @notification_port = notification_port
        @tuple_space = tuple_space
      end

      def notifier
        tuple_space_provider
      end
    end
  end
end
