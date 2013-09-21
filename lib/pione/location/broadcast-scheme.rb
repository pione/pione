module Pione
  module Location
    # BroadcastScheme is a scheme for representing broadcast address.
    # @example
    #   URI.parse("broadcast://255.255.255.255:560001")
    class BroadcastScheme < LocationScheme('broadcast')
      # @api private
      COMPONENT = [:scheme, :host, :port]
    end
  end
end
