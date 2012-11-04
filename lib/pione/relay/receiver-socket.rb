module Pione
  module Relay
    class ReceiverSocket < DRb::DRbTCPSocket
      class ReceiverSocketError < StandardError; end

      @@table = {}

      def self.table
        @@table
      end

      # Parses special URI for reverse scheme.
      def self.parse_uri(uri)
        if uri =~ /^receiver:\/\/(.*?):(\d+)(\?(.*))?$/
          host = $1
          port = $2.to_i
          option = $4
          [host, port, option]
        else
          raise(DRb::DRbBadScheme, uri) unless uri =~ /^receiver:/
          raise(DRb::DRbBadURI, 'can\'t parse uri:' + uri)
        end
      end

      # Raises an error. You cannnot open receiver socket on caller side.
      def self.open(uri, config)
        raise DRb::DRbBadScheme.new(uri)
      end

      # Creates a fake connection.
      # @api private
      def self.open_server(uri, config)
        # reverse socket needs URI always
        raise ArgumentError.new("You should specify receiver URI.") unless uri

        # get config
        host, port, option = parse_uri(uri)

        # retrieve socket by rev_id
        key = "%s:%s" % [host, port]
        unless @@table.has_key?(key)
          raise ReceiverSocketError.new("No socket for %s." % uri)
        end
        socket = @@table[key]

        # create an instance with relay socket
        return self.new(uri, socket, config)
      end

      # Raises an error because the socket cannot accept.
      def accept
        raise ReceiverSocketError.new("ReceiverSocket cannnot accept connections.")
      end

      def close
      end

      def alive?
        true
      end

      def set_socket(*args)
      end
    end

    # install the protocol
    DRb::DRbProtocol.add_protocol(ReceiverSocket)
  end
end
