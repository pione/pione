module Pione
  module TupleSpace
    class TupleSpaceReceiver < PresenceNotifier
      class InstanceError < StandardError; end

      set_command_name "pione-tuple-space-receiver"
      set_notifier_uri Proc.new {Global.tuple_space_receiver_uri}

      def self.start(broker)
        instance.register(broker)
      end

      attr_accessor :drb_service

      def initialize
        @brokers = []
        @tuple_space_servers = {}
        @socket = open_socket

        # lock
        @tuple_space_server_lock = Mutex.new
        @broker_lock = Mutex.new

        # subagents
        @tuple_space_server_receiver =
          Agent::TrivialRoutineWorker.new(Proc.new{receive_tuple_space_servers})
        @updater = Agent::TrivialRoutineWorker.new(
          Proc.new do
            update_tuple_space_servers
          end
        )
      end

      # Registers the agent.
      def register(agent)
        @broker_lock.synchronize { @brokers << agent }
      end

      # Start to receive tuple space servers.
      def start
        @tuple_space_server_receiver.start
        @updater.start
      end

      def tuple_space_servers
        @tuple_space_server_lock.synchronize do
          @tuple_space_servers.keys
        end
      end

      # Send empty tuple space server list.
      def finalize
        @terminated = true
        @tuple_space_server_receiver.terminate
        @socket.close
        @updater.terminate
        @tuple_space_servers = []
      end

      alias :terminate :finalize

      def terminated?
        @terminated
      end

      private

      # Opens receiver socket.
      # @return [UDPSocket]
      #   server socket
      def open_socket
        socket = UDPSocket.open
        socket.bind(Socket::INADDR_ANY, Global.presence_port)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
        return socket
      end

      # Receives tuple space servers and updates the table.
      # @return [void]
      def receive_tuple_space_servers
        provider_front = Marshal.load(@socket.recv(1024))
        begin
          # need return of ping in short time
          Timeout.timeout(1) do
            provider_front.ping
            provider_front.tuple_space_servers.each do |tuple_space_server|
              @tuple_space_server_lock.synchronize do
                @tuple_space_servers[tuple_space_server] = Time.now
              end
            end
          end
        rescue Exception
          # ignore
        end
        if Global.show_presence_notifier
          puts "presence notifier was received: %s" % provider_front.__drburi
        end
      rescue DRb::DRbConnError, DRb::ReplyReaderThreadError, IOError => e
        @socket.close
        @socket = open_socket
        if Global.show_presence_notifier
          puts "tuple space receiver disconnected"
        end
      end

      def update_tuple_space_servers
        # update tuple space server list
        @tuple_space_server_lock.synchronize do
          @tuple_space_servers.delete_if do |server, time|
            begin
              # ping
              timeout(1) { server.ping }
              # check timespan
              (Time.now - time) > Global.tuple_space_receiver_disconnect_time
            rescue
              true
            end
          end
        end

        # update broker
        @broker_lock.synchronize do
          @brokers.select! do |broker|
            begin
              timeout(1) { broker.ping }
              broker.update_tuple_space_servers(tuple_space_servers)
              true
            rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
              puts "dead server"
              false
            end
          end
        end

        sleep 1
      rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
        # ignore
      end
    end
  end
end
