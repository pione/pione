module Pione
  module Relay
    # TransmitterSocket is a connection layer from PIONE relay to PIONE client.
    class TransmitterSocket < DRb::DRbTCPSocket
      class TransmitterSocketError; end

      @@table = {}

      def self.table
        @@table
      end

      # Parses special URI for reverse scheme.
      def self.parse_uri(uri)
        if uri =~ /^transmitter:\/\/([\w-]+)(\?(.*))?$/
          transmitter_id = $1
          option = $3
          return transmitter_id, option
        else
          raise(DRb::DRbBadScheme, uri) unless uri =~ /^transmitter:/
          raise(DRb::DRbBadURI, 'can\'t parse uri:' + uri)
        end
      end

      # Creates a fake connection from relay transmitter to proxy.
      # @api private
      def self.open(uri, config)
        # reverse socket needs URI always
        raise ArgumentError.new("You should specify transmitter URI.") unless uri

        # get transmitter_id
        transmitter_id, option = parse_uri(uri)
        transmitter_id.untaint

        # get the tcp socket that connects to proxy
        unless @@tcp_socket.has_key?(transmitter_id)
          raise TransmitterSocketError.new("No socket for %s." % transmitter_id)
        end
        socket = TCPSocket.new("localhost", @@tcp_socket[transmitter_id])

        # create an instance with  socket
        self.new(uri, socket, config)
      end

      # Opens a fake socket.
      def self.open_server(uri, config)
        # reverse socket needs URI always
        raise ArgumentError.new("You should specify transmitter URI.") unless uri

        # get transmitter_id
        transmitter_id, option = parse_uri(uri)
        transmitter_id.untaint

        # get ssl socket that connects to receiver
        unless @@ssl_socket.has_key?(transmitter_id)
          raise TransmitterSocketError.new("No socket for %s." % transmitter_id)
        end
        ssl_socket = @@ssl_socket[transmitter_id]

        # get the tcp socket that connects to proxy
        unless @@tcp_socket.has_key?(transmitter_id)
          raise TransmitterSocketError.new("No socket for %s." % transmitter_id)
        end
        tcp_socket = @@tcp_socket[transmitter_id]

        # create an instance with relay socket
        self.new(uri, ssl_socket, config)
      end

      def self.uri_option(uri, config)
        transmitter_id, option = parse_uri(uri)
        return "transmitter://%s" % transmitter_id, option
      end

      # Opens fake connection from proxy to transmitter.
      # Just returns self.
      def accept
       return self
      end
    end

    # install the protocol
    DRb::DRbProtocol.add_protocol(TransmitterSocket)
  end
end
