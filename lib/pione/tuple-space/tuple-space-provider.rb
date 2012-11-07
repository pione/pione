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
      def initialize(presence_port)
        super()

        # set variables
        @presence_port = presence_port
        @tuple_space_servers = []
        @terminated = false

        # start agents
        @keeper = Agent::TrivialRoutineWorker.new(Proc.new{send_packet}, 3)
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
      def send_packet
        @ref ||= Marshal.dump(DRbObject.new(Global.front))
        socket = UDPSocket.open
        addr = Socket::INADDR_BROADCAST
        begin
          if Global.show_communication
            puts "sent UDP packet %s port %s at %s" % [addr, @presence_port, Time.now]
          end
          # send packet
          # FIXME: multicast or direct boardcast
          socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
          socket.send(@ref, 0, addr, @presence_port)
        rescue
          nil
        ensure
          socket.close
        end
      end
    end
  end
end
