module Pione
  module Front
    class TupleSpaceProviderFront < BaseFront
      def initialize(druby_port, presence_notification_port)
        @tuple_space_provider = TupleSpaceProvider.new(presence_notification_port)
        super(druby_port)
      end

      def start
        while true do
          break if @tuple_space_provider.tuple_space_servers.size == 0
          sleep 60
        end
      end
    end
  end
end
