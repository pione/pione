module Pione
  module TupleSpace
    # TupleSpaceProvider provides tuple space server's location to tuple space
    # receivers.
    class TupleSpaceProvider < PresenceNotifier
      include DRbUndumped

      set_command_name "pione-tuple-space-provider"
      set_notifier_uri Proc.new {Global.tuple_space_provider_uri}

      attr_accessor :tuple_space_servers

      # Creatas a new server. This method assumes to be called from
      # pione-tuple-space-provider command only. So you should not initialize
      # server directly.
      def initialize
        super

        # set variables
        @tuple_space_servers = []
        @terminated = false

        # start agents
        @keeper = Agent::TrivialRoutineWorker.new(
          Proc.new do
            send_packet
            sleep 5
          end
        )
      end

      def start
        @keeper.start
      end

      def add_tuple_space_server(tuple_space_server)
        @tuple_space_servers << tuple_space_server
      end

      # Sends empty tuple space server list.
      def terminate
        return unless @terminated
        @terminated = true
        @keeper_agent.terminate
      end

      alias :finalize :terminate

      private

      # Sends presence notification to tuple space receivers as UDP packet.
      # @return [void]
      def send_packet
        # setup reference data
        @ref ||= Marshal.dump(DRbObject.new(Global.front))
        # open a socket
        socket = UDPSocket.open
        # address to send broadcast
        addresses = Global.tuple_space_provider_broadcast_addresses
        begin
          if Global.show_presence_notifier
            args = [Global.front.uri, addresses.join(", "), Time.now]
            puts "sent presence notifier from %s to %s at %s" % args
          end
          # send packet
          socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
          addresses.each {|addr| socket.send(@ref, 0, addr.host, addr.port)}
        rescue => e
          if Global.show_presence_notifier
            puts "tuple-space-provider: something is bad..."
            Util::ErrorReport.print(e)
          end
        ensure
          # close the socket always
          socket.close
        end
      end
    end
  end
end
