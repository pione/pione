module Pione
  module Notification
    # `Notification::Transmitter` is a class for transmitting notification
    # messages to target URI.
    class Transmitter
      # Transmit the notification message to the targets.
      #
      # @param message [Notification::Message]
      #    a notfication message
      # @param targets [Array<URI>]
      #    target URIs
      def self.transmit(message, targets=Global.notification_targets)
        targets.each do |uri|
          transmitter = self.new(uri)
          begin
            transmitter.transmit(message)
          rescue => e
            Log::SystemLog.warn('Notification transmitter has failed to transmit to "%s": %s' % [uri, e.message])
          ensure
            transmitter.close
          end
        end
      end

      # a lock for transmitting notification messages
      LOCK = Mutex.new

      # target URI that the transmitter transmits notification messages to
      attr_reader :uri

      # @param uri [URI]
      #   target URI
      def initialize(uri)
        # URI scheme should be "pnb"(UDP broadcast), "pnm"(UDP multicast), or
        # "pnu"(UDP unicast)
        unless ["pnb", "pnm", "pnu"].include?(uri.scheme)
          raise ArgumentError.new(uri)
        end

        if uri.host.nil? or uri.port.nil?
          raise ArgumentError.new(uri)
        end

        @uri = uri
        open
      end

      # Transmit the notification message to target URI.
      #
      # @param message [Notification::Message]
      #   a notification message
      # @return [void]
      def transmit(message)
        LOCK.synchronize do
          @socket.send(message.dump, 0, @uri.host, @uri.port)
        end
      end

      # Close the transmitter's socket.
      def close
        @socket.close
      end

      private

      # Open a UPD socket and configure it by URI scheme.
      def open
        @socket = UDPSocket.open

        case @uri.scheme
        when "pnb"
          # enable broadcast flag
          @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
        when "pnm"
          if @uri.interface
            # enable to bind interface
            interface = IPAddr.new(@uri.interface).hton
            @socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_IF, interface)
          end
        end
      end
    end
  end
end
