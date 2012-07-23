require 'pione/common'
require 'socket'

module Pione
  class TupleSpaceReceiver < PioneObject

    UDP_PORT = 54321
    RECEIVER_URI = "druby://localhost:10107"
    DISCONNECT_TIME = 180
    MAX_RETRY_NUMBER = 10

    class InstanceError < StandardError; end

    # Return the receiver instance.
    def self.instance(data={}, i=0)
      if i >= MAX_RETRY_NUMBER
        raise InstanceError
      end
      uri = if data.has_key?(:receiver_port) then
              "druby://localhost:#{data[:receiver_port]}"
            else RECEIVER_URI end
      # check DRb service
      begin
        DRb.current_server
      rescue
        DRb.start_service
      end
      # remote object
      begin
        # get receiver reference
        receiver = DRbObject.new_with_uri(uri)
        receiver.uuid # check the server exists
        receiver
      rescue
        begin
          # create new receiver
          receiver = self.new(data)
          receiver.drb_service = DRb::DRbServer.new(uri, receiver)
          DRbObject.new_with_uri(uri)
        rescue Errno::EADDRINUSE
          # retry
          sleep 0.1
          instance(data, i+1)
        end
      end
    end

    # Terminate tuple space provider.
    def self.terminate
      # terminate message as remote procedure call causes connection error
      begin
        instance.terminate
      rescue
        # do nothing
      end
    end

    attr_reader :receiver_thread
    attr_reader :updater_thread
    attr_reader :agents
    attr_reader :udp_port

    attr_accessor :drb_service

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

    # Send empty tuple space server list.
    def finalize
      @terminated = true
      @drb_service.stop_service
      # DRbServer#stop_service killed service thread, but sometime it cannot
      # close the socket because ensure clause isn't called in some cases on MRI
      # 1.9.x.
      @drb_service.instance_eval do
        @thread.kill.join
        kill_sub_thread.join
        @protocol.close
      end
      if DRb.primary_server == @drb_service
        DRb.primary_server = nil
      end
      @thread_receive_packet.kill.join
      @thread_update_list.kill.join
      @thread_check_agent_life.kill.join
      @tuple_space_servers = []
    end

    alias :terminate :finalize

    private

    def receive_tuple_space_servers
      @thread_receive_packet = Thread.new do
        loop do
          begin
            msg = @socket.recv(1024)
            provider = Marshal.load(msg)
            time = Time.now
            provider.tuple_space_servers.each do |ts_server|
              @tuple_space_servers[ts_server] = time
            end

            if Pione.debug_mode?
              puts "receive UDP packet..."
            end
          rescue DRb::DRbConnError
            # none
            if Pione.debug_mode?
              puts "tuple space receiver: something bad..."
            end
          end
        end
      end
    end

    def update_tuple_space_servers
      @thread_update_list = Thread.new do
        loop do
          if Pione.debug_mode?
            puts "check for updating tuple space servers"
          end

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
      @thread_check_agent_life = Thread.new do
        while true do
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
