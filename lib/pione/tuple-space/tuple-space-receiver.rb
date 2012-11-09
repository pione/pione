module Pione
  module TupleSpace
    class TupleSpaceReceiver < PresenceNotifier
      class InstanceError < StandardError; end

      set_command_name "pione-tuple-space-receiver"
      set_notifier_uri Proc.new {Global.tuple_space_receiver_uri}

      def self.start(broker)
        instance.register(broker)
      end

      attr_accessor :tuple_space_server
      attr_accessor :drb_service

      def initialize(presence_port)
        @receiver_thread = nil
        @updater_thread = nil
        @brokers = []
        @disconnect_time = Global.tuple_space_receiver_disconnect_time
        @socket = UDPSocket.open
        @socket.bind(Socket::INADDR_ANY, presence_port)
        @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
        @tuple_space_servers = {}
        @mutex = Mutex.new

        # agents
        @receiver = Agent::TrivialRoutineWorker.new(Proc.new{receive_tuple_space_servers}, 0)
        @updater = Agent::TrivialRoutineWorker.new(Proc.new{update_tuple_space_servers}, 1)
        @life_checker = Agent::TrivialRoutineWorker.new(Proc.new{check_agent_life}, 1)
      end

      def register(agent)
        @brokers << agent
      end

      # Start to receive tuple space servers.
      def start
        @receiver.start
        @updater.start
        @life_checker.start
      end

      def tuple_space_servers
        @mutex.synchronize do
          @tuple_space_servers.keys
        end
      end

      # Send empty tuple space server list.
      def finalize
        @terminated = true
        @receiver.terminate
        @updater.terminate
        @life_checker.terminate
        @tuple_space_servers = []
      end

      alias :terminate :finalize

      private

      def receive_tuple_space_servers
        provider_front = Marshal.load(@socket.recv(1024))
        @mutex.synchronize do
          provider_front.tuple_space_servers.each do |tuple_space_server|
            @tuple_space_servers[tuple_space_server] = Time.now
          end
        end
        if Global.show_communication
          puts "tuple space receiver received %s" % provider_front.__drburi
        end
      rescue DRb::DRbConnError => e
        if Global.show_communication
          puts "tuple space receiver is something bad... %s" % e
        end
      end

      def update_tuple_space_servers
        @mutex.synchronize do
          @tuple_space_servers.delete_if do |server, time|
            begin
              server.uuid
              false
            rescue
              true
            end
          end
        end

        # make drop target
        drop_target = []
        @mutex.synchronize do
          @tuple_space_servers.each do |ts_server, time|
            if (Time.now - time) > @disconnect_time
              drop_target << ts_server
            end
          end
        end

        # drop targets
        drop_target.each do |key|
          @mutex.synchronize do
            @tuple_space_servers.delete(key)
          end
        end

        # update
        @brokers.each do |broker|
          begin
            broker.update_tuple_space_servers(tuple_space_servers)
          rescue DRb::DRbConnError
            puts "dead server"
          end
        end
      end

      def check_agent_life
        @brokers.delete_if do |broker|
          begin
            broker.uuid
            false
          rescue DRb::DRbConnError
            true
          end
        end
      end
    end
  end
end
