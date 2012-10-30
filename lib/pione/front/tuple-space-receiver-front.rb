module Pione
  module Front
    # TupleSpaceProviderFront is a front class for pione-tuple-space-receiver
    # command.
    class TupleSpaceReceiverFront < BasicFront
      def_delegator :@command, :tuple_space_receiver
      def_delegator :@command, :presence_port

      def initialize(command)
        super(command, Global.tuple_space_receiver_front_port_range)
      end

      def presence_notifier
        tuple_space_receiver
      end
    end
  end
end
