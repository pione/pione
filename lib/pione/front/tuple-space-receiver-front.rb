module Pione
  module Front
    # TupleSpaceProviderFront is a front interface for
    # +pione-tuple-space-receiver+ command.
    class TupleSpaceReceiverFront < BasicFront
      def initialize
        super(Global.tuple_space_receiver_front_port_range)
      end
    end
  end
end
