module Pione
  module TupleSpace
    # TupleSpaceProvider provides tuple space server's location to tuple space
    # receivers.
    class TupleSpaceProvider < PioneObject
      include DRbUndumped

      @monitor = Monitor.new

      # Creates the tuple space provider as new process.
      # @return [TupleSpaceProviderFront]
      #   tuple space provider front
      def self.spawn
        user_message "create process for tuple space provider"
        # create provider process
        pid = Process.spawn(
          'pione-tuple-space-provider',
          '--presence-port', CONFIG.presence_port.to_s,
          '--caller-front', Pione.front.uri
        )
        thread = Process.detach(pid)
        # wait that the provider starts up
        while thread.alive?
          begin
            # get front
            provider_front = DRbObject.new_with_uri(Pione.tuple_space_provider_uri)
            break if provider_front.uuid
          rescue
            sleep 0.1
          end
        end
        if thread.alive?
          return provider_front
        else
          # failed to run pione-tuple-space-provider
          Process.abort("You cannot run pione-tuple-space-provider.")
        end
      end

      # Returns the provider instance.
      # @return [TupleSpaceProvider]
      #   tuple space provider instance as druby object
      def self.instance
        @monitor.synchronize do
          # get provider reference
          begin
            front = DRbObject.new_with_uri(
              Pione.tuple_space_provider_uri
            )
            front.uuid
            front
          rescue
            # create new provider
            self.spawn
          end.tuple_space_provider
        end
      end

      # Creatas a new server. This method assumes to be called from
      # pione-tuple-space-provider command only. So you should not initialize
      # server directly.
      def initialize(presence_port=CONFIG.presence_port)
        super()

        # set variables
        @monitor = Monitor.new
        @expiration_time = 5
        @presence_port = presence_port
        @tuple_space_servers = {}
        @terminated = false

        # start agents
        @keeper = Agent::TrivialRoutineWorker.new(Proc.new{send_packet}, 3)
        @cleaner = Agent::TrivialRoutineWorker.new(Proc.new{clean}, 3)
      end

      def start
        @keeper.start
        @cleaner.start
      end

      # Adds the tuple space server.
      def add(tuple_space_server)
        @monitor.synchronize do
          @tuple_space_servers[tuple_space_server] = Time.now
        end
      end

      # Returns the process provider's current pid
      def pid
        Process.pid
      end

      # Returns tuple space servers.
      def tuple_space_servers
        @monitor.synchronize do
          @tuple_space_servers.keys
        end
      end

      # Sends empty tuple space server list.
      def terminate
        return unless @terminated
        @terminated = true
        @keeper_agent.terminate
        @cleaner_agent.terminate
      end

      alias :finalize :terminate

      private

      # Sends presence notification to tuple space receivers as UDP packet.
      def send_packet
        @ref ||= Marshal.dump(DRbObject.new(self))
        socket = UDPSocket.open
        begin
          if debug_mode?
            puts "sent UDP packet ..."
          end
          # enable broadcast
          socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
          # send packet
          #socket.send(@remote_object, 0, Socket::INADDR_BROADCAST, @udp_port)
          socket.send(@ref, 0, '192.168.56.255', @presence_notification_port)
        rescue
          nil
        ensure
          socket.close
        end
      end

      # Cleans dead or expired tuple space servers.
      def clean
        @monitor.synchronize do
          targets = []

          # find dead or expired servers
          @tuple_space_servers.each do |server, time|
            begin
              if server.alive? and (Time.now - time > @expiration_time)
                targets << server
              end
            rescue
              targets << server
            end
          end

          # delete target servers
          targets.each {|server| @tuple_space_servers.delete(server)}
        end
      end
    end
  end
end
