module Pione
  module Front
    # TupleSpaceProviderFront is a front interface for
    # pione-tuple-space-provider command.
    class TupleSpaceProviderFront < BasicFront
      attr_reader :tuple_space

      forward :@command, :agent
      forward :@command, :presence_port

      def initialize(command, tuple_space)
        super(command, Global.tuple_space_provider_front_port_range)
        @tuple_space = tuple_space
      end
    end
  end
end
