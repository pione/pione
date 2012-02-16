require 'socket'
require 'drb/drb'
require 'innocent-white/innocent-white-object'

module InnocentWhite
  class TupleSpaceReceiver < InnocentWhiteObject

    UDP_PORT = 54321
    RECEIVER_URI = "druby://localhost:10102"
    DISCONNECT_TIME = 180

    # -- class --

    # Return the receiver instance.
    def self.get(data={})
      uri = if data.has_key?(:receiver_port) then
              "druby://localhost:#{data[:receiver_port]}"
            else RECEIVER_URI end
      begin
        obj = DRbObject.new_with_uri(uri)
        obj.uuid # check the receiver exists
        return obj
      rescue
        # receiver not exists
        receiver = self.new(data)
        DRb.start_service(uri, receiver)
        return receiver
      end
    end

    # -- object --

    attr_reader :receiver_thread
    attr_reader :updater_thread
    attr_reader :agents
    attr_reader :udp_port

    def initialize(data={})
      # check argument
      if (data.keys - [:receiver_port, :udp_port, :disconnect_time]).size > 0
        raise ArgumentError
      end

      # initialize variables
      @receiver_thread = nil
      @updater_thread = nil
      @agents = []
      @udp_port = data.has_key?(:udp_port) ? data[:udp_port] : UDP_PORT
      @disconnect_time = data.has_key?(:disconnect_time) ? data[:disconnect_time] : DISCONNECT_TIME
      @socket = UDPSocket.open
      @socket.bind('', @udp_port)
      @tuple_space_servers = {}

      # start
      run
    end

    def register(agent)
      @agents << agent
    end

    # Start to receive tuple space servers.
    def run
      receive_tuple_space_servers
      update_tuple_space_servers
      check_agent_life
    end

    def tuple_space_servers
      @tuple_space_servers.keys
    end

    private

    def receive_tuple_space_servers
      @receiver_thread = Thread.new do
        loop do
          begin
            msg = @socket.recv(1024)
            provider = Marshal.load(msg)
            time = Time.now
            provider.tuple_space_servers.each do |ts_server|
              @tuple_space_servers[ts_server] = time
            end

            if InnocentWhite.debug_mode?
              puts "receive UDP packet..."
            end
          rescue DRb::DRbConnError
            # none
            if InnocentWhite.debug_mode?
              puts "tuple space receiver: something bad..."
            end
          end
        end
      end
    end

    def update_tuple_space_servers
      @updater_thread = Thread.new do
        loop do
          puts "check for updating tuple space servers"

          @tuple_space_servers.delete_if do |ts_server, time|
            begin
              ts_server.uuid
              false
            rescue DRb::DRbConnError
              true
            end
          end

          # make drop target
          drop_target = []
          @tuple_space_servers.each do |ts_server, time|
            if (Time.now - time) > @disconnect_time
              drop_target << ts_server
            end
          end

          # drop targets
          drop_target.each do |key|
            @tuple_space_servers.delete(key)
          end

          # update
          @agents.each do |agent|
            begin
              p tuple_space_servers
              agent.update_tuple_space_servers(tuple_space_servers)
            rescue DRb::DRbConnError
              puts "dead server or agent"
              # none
            end
          end

          # sleep and go next...
          sleep 1
        end
      end
    end

    def check_agent_life
      @check_agent_life_thread = Thread.new do
        loop do
          list = []
          @agents.each do |agent|
            begin
              agent.uuid
              list << agent
            rescue DRb::DRbConnError
              # none
            end
          end
          @agents = list

          sleep 1
        end
      end
    end

  end
end
