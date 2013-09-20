module Pione
  module Front
    # TupleSpaceProviderFront is a front interface for
    # pione-tuple-space-provider command.
    class TupleSpaceProviderFront < BasicFront
      attr_reader :tuple_space

      def initialize(tuple_space)
        super(Global.tuple_space_provider_front_port_range)
        @tuple_space = tuple_space
      end
    end
  end
end
