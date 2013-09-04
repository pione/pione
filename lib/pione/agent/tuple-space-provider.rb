module Pione
  module Agent
    # TupleSpaceProvider is an agent that provides tuple space.
    class TupleSpaceProvider < BasicAgent
      set_agent_type :tuple_space_provider, self

      #
      # instance methods
      #

      def initialize(front)
        super()
        @front = front
        @reference = Marshal.dump(/druby:\/\/(.*):(\d+)/.match(@front.uri)[2].to_i)
      end

      #
      # agent activities
      #

      define_transition :send_packet
      define_transition :sleep

      chain :init => :send_packet
      chain :send_packet => :sleep
      chain :sleep => :send_packet

      #
      # transitions
      #

      def transit_to_send_packet
        send_packet
      end

      def transit_to_sleep
        sleep 5
      end

      #
      # helper methods
      #

      # Send presence notification packets to tuple space receivers.
      def send_packet
        # open a UDP socket
        socket = UDPSocket.open
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)

        # send broadcast packets
        Global.presence_notification_addresses.each do |address|
          begin
            ErrorReport.presence_notifier(build_debug_message(address), self, __FILE__, __LINE__)
            socket.send(@reference, 0, address.host, address.port)
          rescue => e
            msg = "something is bad when tuple space provider sends a packet"
            Util::ErrorReport.warn(msg, self, e, __FILE__, __LINE__)
          end
        end
      ensure
        socket.close
      end

      # Build a debug message.
      def build_debug_message(address)
        "sent presence notifier from %s to %s at %s" % [@front.uri, address, Time.now]
      end
    end
  end
end
