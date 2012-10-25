module Pione
  module Front
    class RelayFront < BasicFront
      def_delegator :@command, :presence_port

      def presence_notifier
        tuple_space_provider
      end

      def tuple_space_server
        tuple_space_provider.tuple_space_server
      end
    end
  end
end
