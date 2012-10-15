module Pione
  # TupleSpaceProvider provides tuple space server's location to tuple space
  # receivers.
  class TupleSpaceProvider < PioneObject
    include DRbUndumped

    PRESENCE_NOTIFICATION_PORT = 55000
    DRUBY_PORT = 54000

    Params = Struct.new(:presence_notification_port, :provider_port, :expiration_time)

    class << self
      # Creates the tuple space provider as new process.
      # @param [Integer] port
      #   provider port
      # @return [TupleSpaceProviderFront]
      #   tuple space provider front
      def spawn(params)
        # create provider process
        Process.spawn("pione-tuple-space-provider", front.uri, port)
        # get front
        provider_front = DRbObject.new_with_uri("druby://localhost:%s" % params.druby_port)
        # wait that the provider starts up
        while true
          begin
            break if provider_front.uuid
          rescue
            sleep 0.1
          end
        end
        return provider_front
      end

      # Returns the provider instance.
      # @param [Integer] port
      #   provider port
      # @return [TupleSpaceProvider]
      #   tuple space provider instance as druby object
      def instance(druby_port=PROVIDER_PORT)
        # get provider reference
        front = DRbObject.new_with_uri(uri)
        front.provider
      rescue
        # create new provider
        self.spawn(port)
      end
    end

    # Returns presence notification port number
    attr_reader :presence_notification_port
    # Returns druby service port number
    attr_reader :druby_port

    # Creatas a new server. This method assumes to be called from
    # pione-tuple-space-provider command only. So you should not initialize
    # server directly.
    def initialize(option=Option.new)
      super()

      # set variables
      @monitor = Monitor.new
      @expiration_time = 5
      @presence_notification_port = CONFIG.presence_notification
      @tuple_space_servers = {}
      @ref = Marshal.dump(DRbObject.new(self))
      @terminated = false

      # start agents
      @keeper = Agent::TrivialRoutineWorker.start(Proc.new{send_packet}, 3)
      @cleaner = Agent::TrivialRoutineWorker.start(Proc.new{clean}, 3)
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
