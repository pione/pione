module Pione
  module Agent
    class TupleSpaceReceiver < BasicAgent
      #
      # instance methods
      #

      def initialize(broker)
        super()
        @broker = broker
        @tuple_space_server_lock = Mutex.new
      end

      def tuple_space_servers
        @tuple_space_servers.keys
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
        @tuple_space_servers = {}
        @socket = open_socket
      end

      # Receive tuple space servers and updates the table.
      def transit_to_receive_packet
        data, addr = @socket.recvfrom(1024)
        port = Marshal.load(data).to_i
        ip_address = addr[3]
        provider_front = DRbObject.new_with_uri("druby://%s:%s" % [ip_address, port])

        # need return of ping in short time
        Timeout.timeout(1) do
          provider_front.ping
          @tuple_space_server_lock.synchronize do
            @tuple_space_servers[provider_front.tuple_space] = Time.now
          end
        end

        if Global.show_presence_notifier
          puts "presence notifier was received: %s" % provider_front.__drburi
        end
      rescue DRb::DRbConnError, DRb::ReplyReaderThreadError, IOError => e
        @socket.close
        @socket = open_socket
        if Global.show_presence_notifier
          puts "tuple space receiver disconnected: %s" % e
        end
      end

      # Send empty tuple space server list.
      def transit_to_terminate
        @socket.close
        @tuple_space_servers = []
      end

      def transit_to_update_broker
        # update tuple space server list
        @tuple_space_server_lock.synchronize do
          @tuple_space_servers.delete_if do |server, time|
            begin
              # check timespan
              (Time.now - time) > Global.tuple_space_receiver_disconnect_time
            rescue Exception
              true
            end
          end
        end

        # update broker's tuple spaces
        begin
          @broker.update_tuple_space_list(@tuple_space_servers)
        rescue Exception => e
          ErrorReport.error("broker may be dead", self, e, __FILE__, __LINE__)
          terminate
        end
      end

      def transit_to_sleep
        sleep 1
      end

      #
      # helper methods
      #

      # Open receiver socket.
      def open_socket
        socket = UDPSocket.open
        socket.bind(Socket::INADDR_ANY, Global.presence_port)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
        return socket
      end
    end
  end
end
