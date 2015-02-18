module Pione
  module Notification
    # `Notification::Receiver` provides the function to receive notification
    # packets. Be careful we assume notification's packet is small.
    class Receiver
      # a lock for receiving notifications
      LOCK = Mutex.new

      MAX_SIZE = 65535

      # @param uri [URI]
      #   URI of receiver address
      def initialize(uri)
        unless ["pnb", "pnm", "pnu"].include?(uri.scheme)
          raise ArgumentError.new(uri)
        end

        @uri = uri
        open
      end

      # Receive a notification packet.
      def receive
        data, addr = LOCK.synchronize {@socket.recvfrom(MAX_SIZE)}
        ip_address = addr[3]
        message = Message.load(data)
        Log::SystemLog.debug(
          "Notification data has been received from %s: {notifier: %s, type: %s}." %
          [ip_address, message.notifier, message.type])
        return [ip_address, message]
      rescue TypeError, NoMethodError
        ip_address = ip_address || "(unknown)"
        Log::Debug.notification("Invalid data has been received from %s." % ip_address)
        retry
      end

      # Close and open receiver socket.
      def reopen
        close
        open(@host, @port)
      end

      # Close the receiver socket.
      def close
        @socket.close
      end

      # Return true if receiver socket is closed.
      #
      # @return [Boolean]
      #   true if receiver socket is closed
      def closed?
        @socket.closed?
      end

      private

      # Open a receiver socket with the port number. Be careful that Linux seems
      # to require INADDR_ANY to receive broadcast packets, and Windows seems
      # not to require.
      #
      # @return [void]
      def open
        _host = IPSocket.getaddress(@uri.host)

        @socket = UDPSocket.open
        @socket.bind(_host, @uri.port)

        case @uri.scheme
        when "pnb"
          unless not(OS.windows?) and IPAddr.new(_host) == Socket::INADDR_ANY
            msg = [
              "Notification receiver address %p is not INADDR_ANY(%p), ",
              "this may cause to fail receiving broadcast packets. ",
              "If you can receive it, please tell me your platform name."
            ].join
            Log::SystemLog.warn(msg % [@uri.host, "0.0.0.0"])
          end

          @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
        when "pnm"
          group = IPAddr.new(@uri.host).hton
          if @uri.interface
            interface = IPAddr.new(@uri.interface).hton
          else
            interface = IPAddr.new(Addrinfo.ip(Socket::INADDR_ANY).ip_address).hton
          end
          @socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, group + interface)
        end
      end
    end
  end
end
