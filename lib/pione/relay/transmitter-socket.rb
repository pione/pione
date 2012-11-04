module Pione
  module Relay
    # TransmitterSocket is a connection layer from PIONE relay to PIONE client.
    class TransmitterSocket < DRb::DRbTCPSocket
      class TransmitterSocketError; end

      @@receiver_socket = {}
      @@proxy_socket = {}

      def self.receiver_socket
        @@receiver_socket
      end

      def self.proxy_socket
        @@proxy_socket
      end

      # Parses special URI for reverse scheme.
      def self.parse_uri(uri)
        if uri =~ /^transmitter:\/\/([\w-]+)(\?(.*))?$/
          transmitter_id = $1
          option = $3
          return transmitter_id, option
        else
          raise DRb::DRbBadScheme.new(uri) unless uri =~ /^transmitter:/
          raise DRb::DRbBadURI.new('can\'t parse uri:' + uri)
        end
      end

      # Creates a fake connection from proxy to relay transmitter.
      # @api private
      def self.open(uri, config)
        # reverse socket needs URI always
        raise ArgumentError.new("You should specify transmitter URI.") unless uri

        # get transmitter_id
        transmitter_id, _ = parse_uri(uri)
        transmitter_id.untaint

        # get proxy side socket
        soc = @@proxy_socket[transmitter_id]
        unless soc
          msg = "No receiver side socket for %s." % transmitter_id
          raise TransmitterSocketError.new(msg)
        end
        proxy_socket = TCPSocket.new("localhost", soc)

        # create instance with proxy socket
        self.new(uri, nil, proxy_socket, config)
      end

      # Opens a fake socket.
      def self.open_server(uri, config)
        # the method needs URI explicitly
        raise ArgumentError.new("You should specify transmitter URI.") unless uri

        # get transmitter_id
        transmitter_id, _ = parse_uri(uri)
        transmitter_id.untaint

        # get receiver side socket
        receiver_socket = @@ssl_socket[transmitter_id]
        unless receiver_socket
          msg = "No receiver side sockets for %s." % transmitter_id
          raise TransmitterSocketError.new(msg)
        end

        # get proxy side socket
        proxy_socket = @@tcp_socket[transmitter_id]
        unless proxy_socket
          msg = "No proxy side sockets for %s." % transmitter_id
          raise TransmitterSocketError.new(msg)
        end

        # create instance with receiver and proxy sockets
        self.new(uri, receiver_socket, proxy_socket, config)
      end

      def self.uri_option(uri, config)
        transmitter_id, option = parse_uri(uri)
        return "transmitter://%s" % transmitter_id, option
      end

      def initialize(uri, receiver_socket, proxy_socket, config)
        @uri = uri
        @receiver_socket = reciver_socket
        @proxy_socket = proxy_socket
        @acl = config[:tcp_acl]
        @receiver_msg = DRbMessage.new(config)
        @proxy_msg = DRbMessage.new(config)
        set_socket(@receiver_socket) if @receiver_socket
        set_socket(@proxy_socket) if @proxy_socket
      end

      # Sends a request from transmitter to receiver.
      # @api private
      def send_request(ref, msg_id, arg, b)
        @receiver_msg.send_request(@receiver_socket, ref, msg_id, arg, b)
      end

      # Receives a request from proxy to transmitter.
      # @api private
      def recv_request
        @proxy_msg.recv_request(@proxy_socket)
      end

      # Sends a reply from transmitter to proxy.
      # @api private
      def send_reply(req_id, succ, result)
        @proxy_msg.send_reply(req_id, @proxy_socket, succ, result)
      end

      # Receives a reply from receiver to transmitter.
      # @api private
      def recv_reply
        @receiver_msg.recv_reply(@receiver_socket)
      end

      # Opens fake connection from proxy to transmitter.
      # Just returns self.
      def accept
        begin
          while true
            soc = @proxy_socket.accept
            break if (@acl ? @acl.allow_socket?(soc) : true)
            soc.close
          end

      end
    end

    # install the protocol
    DRb::DRbProtocol.add_protocol(TransmitterSocket)
  end
end
