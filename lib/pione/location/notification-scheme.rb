module Pione
  module Location
    # `NotificationBroadcastScheme` is a scheme for PIONE notification protocol
    # using UDP broadcast.
    #
    # @example
    #     URI.parse("pnb://255.255.255.255:56000")
    class NotificationBroadcastScheme < LocationScheme('pnb')
      COMPONENT = [:scheme, :host, :port]
    end

    # `NotificationUnicastScheme` is a scheme for PIONE notification protocol
    # using UDP unicast.
    #
    # @example
    #   URI.parse("pnu://192.168.100.10:56000")
    class NotificationUnicastScheme < LocationScheme('pnu')
      COMPONENT = [:scheme, :host, :port]
    end

    # `NotificationMulticastScheme` is a scheme for PIONE notification protocol
    # using UDP multicast.
    #
    # @example
    #     URI.parse("pnm://239.1.2.3:56000")
    #     URI.parse("pnm://239.1.2.4.56000?if=192.168.100.100")
    class NotificationMulticastScheme < LocationScheme('pnm')
      COMPONENT = [:scheme, :host, :port, :query] # path is fake

      def interface
        query_table["if"] if query
      end

      private

      def query_table
        if query
          query.split("&").each_with_object({}) do |part, table|
            key, val = part.split("=")
            table[key] = val
          end
        end
      end
    end
  end
end
