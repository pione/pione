module Pione
  module Agent
    class TupleSpaceReceiver < BasicAgent
      #
      # instance methods
      #

      # notification handler threads
      attr_reader :notification_handlers

      def initialize(broker_front)
        super()
        @broker_front = broker_front  # broker front
        @tuple_space = {}             # tuple space table
        @tuple_space_lock = Mutex.new # lock for tuple space table
        @notification_handlers = ThreadGroup.new
      end

      def tuple_spaces
        @tuple_space_lock.synchronize {@tuple_space.keys}
      end

      #
      # agent activities
      #

      define_transition :receive_packet
      define_transition :update_broker
      define_transition :sleep

      chain :init => [:receive_packet, :update_broker]
      chain :receive_packet => :receive_packet
      chain :update_broker => :sleep
      chain :sleep => :update_broker

      #
      # transitions
      #

      def transit_to_init
        @tuple_space = {}
        @socket = open_socket
      end

      # Receive tuple space servers and update the table.
      def transit_to_receive_packet
        # receive a notification
        data, addr = @socket.recvfrom(1024)
        ip_address = addr[3]
        port = Marshal.load(data).to_i

        # handle the notification in new thread
        thread = Util::FreeThreadGenerator.generate do
          handle_notification(ip_address, port)
        end
        @notification_handlers.add(thread)
      rescue IOError => e
        Log::Debug.notification("receiver agent received bad data from %s, so it ignored and reopen socket" % ip_address)
        reopen_socket
      end

      # Close receiver socket.
      def transit_to_terminate
        # kill threads of notification handler
        @notification_handlers.list.each {|thread| thread.kill.join}
        # close socket
        @socket.close unless @socket.closed?
      end

      def transit_to_update_broker
        # update tuple space server list
        @tuple_space_lock.synchronize do
          # check timespan
          @tuple_space.delete_if do |server, time|
            (Time.now - time) > Global.tuple_space_receiver_disconnect_time
          end
        end

        # update broker's tuple spaces
        timeout(3) do
          @tuple_space_lock.synchronize do
            @broker_front.update_tuple_space_list(@tuple_space.keys)
          end
        end
      rescue DRb::DRbConnError, Timeout::Error => e
        Log::SystemLog.fatal do
          msg = e.message
          destination = @broker_front.uri
          "Tuple space receiver has failed to connect %s: %s" % [destination, msg]
        end
        raise ConnectionError.new
      end

      def transit_to_sleep
        sleep 1
      end

      #
      # helper methods
      #

      private

      # Open a receiver socket.
      def open_socket
        socket = UDPSocket.open
        socket.bind(Socket::INADDR_ANY, Global.notification_port)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
        return socket
      end

      def reopen_socket
        @socket.close
        @socket = open_socket
      end

      def handle_notification(ip_address, port)
        # build a reference to provider front
        provider_front = DRbObject.new_with_uri("druby://%s:%s" % [ip_address, port])

        # check connection
        Timeout.timeout(3) {provider_front.ping}

        @tuple_space_lock.synchronize do
          @tuple_space[provider_front.tuple_space] = Time.now
        end

        Log::Debug.notification do
          "receiver agent received a notification from provider \"%s\"" % provider_front.__drburi
        end
      rescue Timeout::Error
        Log::Debug.notification do
          "receiver agent ignored the provider \"%s\" that seems to be something bad " % provider_front.__drburi
        end
      rescue DRb::DRbConnError, DRbPatch::ReplyReaderError => e
        reopen_socket
        Log::Debug.notification("tuple space receiver disconnected: %s" % e)
      end
    end
  end
end
