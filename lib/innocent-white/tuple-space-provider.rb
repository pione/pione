require 'drb/drb'
require 'rinda/tuplespace'
require 'innocent-white/innocent-white-object'

module InnocentWhite
  class TupleSpaceProvider < InnocentWhiteObject

    RECEIVER_PORT = 54321
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
        DRb.start_service(uri, self.new(data))
        DRbObject.new_with_uri(uri)
      end
    end

    # -- instance --

    attr_reader :thread
    attr_accessor :timeout
    attr_accessor :receiver_port

    def initialize(data={})
      raise ArgumentError if (data.keys - [:provider_port, :receiver_port, :timeout]).size > 0
      @timeout = data.has_key?(:timeout) ? data[:timeout] : TIMEOUT
      @receiver_port = data.has_key?(:receiver_port) ? data[:receiver_port] : RECEIVER_PORT
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
          begin
            # send UDP packet
            socket = UDPSocket.open
            socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
            socket.send(dump, 0, '<broadcast>', @receiver_port)
          rescue
            nil
          ensure
            socket.close
          end
          sleep @timeout
        end
      end
    end

    # Add the tuple space server.
    def add(ts_server)
      server = DRb.start_service(nil, ts_server)
      @list << DRbObject.new_with_uri(server.uri)
    end

    # Return tuple space servers.
    def tuple_space_servers
      @list
    end
  end

end
