module Pione
  module Front
    # TupleSpaceProviderFront is a front class for pione-tuple-space-provider
    # command.
    class TupleSpaceProviderFront < BasicFront
      attr_reader :tuple_space_provider

      # Create a tuple space provider's front.
      def initialize(druby_port, presence_port)
        @tuple_space_provider = TupleSpaceProvider.new(presence_port)
        super(druby_port)
      end

      # Starts the activity.
      def start
        while true do
          sleep 15

          # stop if tuple space servers are empty
          break if @tuple_space_provider.tuple_space_servers.size == 0
        end
      end
    end
  end
end
