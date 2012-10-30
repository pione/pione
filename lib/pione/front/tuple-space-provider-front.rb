module Pione
  module Front
    # TupleSpaceProviderFront is a front class for pione-tuple-space-provider
    # command.
    class TupleSpaceProviderFront < BasicFront
      def_delegator :@command, :tuple_space_provider
      def_delegator :@command, :presence_port

      def initialize(command)
        super(command, Global.tuple_space_provider_front_port_range)
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
