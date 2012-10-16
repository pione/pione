module Pione
  module Front
    # TupleSpaceProviderFront is a front class for pione-tuple-space-provider
    # command.
    class TupleSpaceProviderFront < BasicFront
      # Create a tuple space provider's front.
      def initialize(druby_port, presence_notification_port)
        @tuple_space_provider = TupleSpaceProvider.new(presence_notification_port)
        super(druby_port)
      end

      # Starts the activity.
      def start
        while true do
          # stop if tuple space servers are empty
          break if @tuple_space_provider.tuple_space_servers.size == 0
          sleep 15
        end
      end
    end
  end
end
