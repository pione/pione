module Pione
  module Front
    # TupleSpaceProviderFront is a front interface for
    # pione-tuple-space-provider command.
    class TupleSpaceProviderFront < BasicFront
      def initialize(cmd)
        super(cmd, Global.tuple_space_provider_front_port_range)
      end

      def tuple_space
        @cmd.model[:tuple_space]
      end
    end
  end
end
