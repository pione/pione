module Pione
  module Front
    # TupleSpaceProviderFront is a front class for pione-tuple-space-provider
    # command.
    class TupleSpaceProviderFront < BasicFront
      extend Forwardable

      def_delegator :@command, :tuple_space_provider
      def_delegator :@command, :presence_port

      # Create a tuple space provider's front.
      def initialize(command)
        super(command, nil)
      end
    end
  end
end
