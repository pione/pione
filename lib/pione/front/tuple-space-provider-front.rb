module Pione
  module Front
    # TupleSpaceProviderFront is a front interface for
    # pione-tuple-space-provider command.
    class TupleSpaceProviderFront < BasicFront
      attr_reader :tuple_space

      def initialize(cmd)
        tuple_space = cmd.model[:parent_front].get_tuple_space(nil)
        super(cmd, Global.tuple_space_provider_front_port_range)
        @tuple_space = tuple_space
      end
    end
  end
end
