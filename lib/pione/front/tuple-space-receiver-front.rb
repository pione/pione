module Pione
  module Front
    # TupleSpaceProviderFront is a front class for pione-tuple-space-receiver
    # command.
    class TupleSpaceReceiverFront < BasicFront
      def_delegator :@command, :tuple_space_receiver
      def_delegator :@command, :presence_port

      def presence_notifier
        tuple_space_receiver
      end
    end
  end
end
