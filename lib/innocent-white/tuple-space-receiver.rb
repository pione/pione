require 'socket'
require 'drb/drb'
require 'innocent-white/innocent-white-object'


module InnocentWhite
  class TupleSpaceReceiver < InnocentWhiteObject
    
    UDP_PORT = 54321
    RECEIVER_URI = "druby://localhost:10102"
    DISCONNECT_TIME = 180

    # Return the receiver instance.
    def self.get(data={})
      uri = data.has_key?(:receiver_port) ? "druby://localhost:#{data[:receiver_port]}" : RECEIVER_URI
      begin
        obj = DRbObject.new_with_uri(uri)
        obj.uuid # check the receiver exists
        return obj
      rescue
        receiver = self.new(data)
        DRb.start_service(uri, receiver)
        return receiver
      end
    end

    attr_reader :receiver_thread
    attr_reader :agents
    attr_reader :udp_port

    def initialize(data={})
      raise ArgumentError if (data.keys - [:receiver_port, :udp_port, :disconnect_time]).size > 0
      @receiver_thread = nil
      @agents = []
      @udp_port = data.has_key?(:udp_port) ? data[:udp_port] : UDP_PORT
      @disconnect_time = data.has_key?(:disconnect_time) ? data[:disconnect_time] : DISCONNECT_TIME
      @socket = UDPSocket.open
      @socket.bind('',@udp_port)
      @tuple_space_servers = {}
      run
    end

    def register(agent)
      @agents << agent
    end

    # Start to receive tuple space servers.
    def run
      receive_tuple_space_servers
      update_tuple_space_servers
    end

    def tuple_space_servers
      @tuple_space_servers.keys
    end

    private

    def receive_tuple_space_servers
      @receiver_thread = Thread.new do
        loop do
          msg = @socket.recv(1024)
          provider = Marshal.load(msg)
          time = Time.now
          provider.tuple_space_servers.each do |ts_server|
            @tuple_space_servers[ts_server] = time
          end
        end
      end
    end

    def update_tuple_space_servers
      @update_thread = Thread.new do
        loop do
          # make drop target
          drop_target = []
          @tuple_space_servers.each do |ts_server, time|
            drop_target << ts_server if (Time.now - time) > @disconnect_time
          end

          # drop targets
          drop_target.each do |key|
            @tuple_space_servers.delete(key)
          end

          # update
          @agents.each{|agent| agent.update_tuple_space_servers(@tuple_space_servers.clone)}

          sleep 1
        end
      end
    end

  end
end
