require 'socket'
require 'drb/drb'
require 'rinda/tuplespace'
require 'innocent-white/common'

module InnocentWhite
  class TupleSpaceProvider < InnocentWhiteObject

    UDP_PORT = 54321
    PROVIDER_URI = "druby://localhost:10101"
    TIMEOUT = 5

    # -- class  --

    # Return the provider instance.
    def self.get(data = {})
      uri = data.has_key?(:provider_port) ? "druby://localhost:#{data[:provider_port]}" : PROVIDER_URI
      begin
        provider = DRbObject.new_with_uri(uri)
        provider.uuid # check the server exists
        provider
      rescue
        #Process.fork do
          DRb.start_service(uri, self.new(data))
          # Process.daemon
          #DRb.thread.join
        #end
        DRbObject.new_with_uri(uri)
      end
    end

    # -- instance --

    attr_reader :thread
    attr_accessor :timeout
    attr_accessor :receiver_port

    def initialize(data={})
      raise ArgumentError if (data.keys - [:provider_port, :udp_port, :timeout]).size > 0
      @timeout = data.has_key?(:timeout) ? data[:timeout] : TIMEOUT
      @udp_port = data.has_key?(:udp_port) ? data[:udp_port] : UDP_PORT
      @thread = nil
      @list = []
      run
    end

    # Return dumped object.
    def dump
      Marshal.dump(DRbObject.new(self))
    end

    # Start to run the provider.
    def run
      @thread = Thread.new do
        loop do
          send_packet
          sleep @timeout
        end
      end

      @check_thread = Thread.new do
        loop do
          check_tuple_space_server_life
          sleep 1
        end
      end
    end

    # Add the tuple space server.
    def add(ts_server)
      server = DRb.start_service(nil, ts_server)
      @list << DRbObject.new_with_uri(server.uri)
      send_packet
    end

    # Return tuple space servers.
    def tuple_space_servers
      @list
    end

    def check_tuple_space_server_life
      old_list = @list
      new_list = []
      @list.each do |server|
        begin
          server.uuid
          new_list << server
        rescue
          # none
        end
      end
      @list = new_list

      # the list was updated, send a packet again
      if not((old_list - new_list).empty?) or not((new_list - old_list).empty?)
        send_packet
      end
    end

    def finalize
      puts "finalize taple space provider #{uuid}"
      @list = []
      send_packet
    end

    private

    def send_packet
      begin
        # send UDP packet
        puts "sent UDP packet ..."
        p @list
        socket = UDPSocket.open
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
        #socket.send(dump, 0, '<broadcast>', @udp_port)
        #socket.send(dump, 0, Socket::INADDR_BROADCAST, @udp_port)
        socket.send(dump, 0, '255.255.255.255', @udp_port)
      rescue
        nil
      ensure
        socket.close
      end
    end

  end

end
