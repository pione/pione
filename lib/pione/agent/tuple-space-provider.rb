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

      # Send notification packets to tuple space receivers.
      def send_packet
        # open a UDP socket
        socket = UDPSocket.open
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)

        # send broadcast packets
        Global.notification_addresses.each do |address|
          begin
            Log::Debug.notification do
              "provider sends notification packet from %s to %s" % [@front.uri, address, Time.now]
            end
            socket.send(@reference, 0, address.host, address.port)
          rescue => e
            Log::SystemLog.warn("tuple space provider agent failed to send a packet: %s" % e.message)
          end
        end
      ensure
        socket.close
      end
    end
  end
end
