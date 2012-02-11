require 'drb/drb'
require 'rinda/tuplespace'

module InnocentWhite
  class TupleSpaceProvider
    PORT = 10101
    TIMEOUT = 5

    attr_reader :thread
    attr_accessor :port
    attr_accessor :timeout

    def initialize(data)
      @thread = nil
      @port = data[:port] || PORT
      @timeout = data[:timeout] || TIMEOUT
      @tuple_space = Rinda::TupleSpace.new
    end

    def provider
      Marshal.dump(DRbObject.new(self))
    end

    def provide
      @thread = Thread.new do
        loop do
          begin
            # send UDP packet
            socket = UDPSocket.open
            socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
            socket.send(provider, 0, '<broadcast>', @port)
          rescue
            nil
          ensure
            socket.close
          end
          sleep @timeout
        end
      end
    end

    def start_service(tuple_space)
      server = DRb.start_service(nil, tuple_space)
      obj = DRbObject.new(server.uri)
      @tuple_space.write [:tuple_space, obj]
    end

    def tuple_spaces(agent_type)
      @tuple_space.read_all([:tuple_space, nil])
    end
  end

  def self.tuple_space_provider
    begin
      DRbObject.new_with_uri(TupleSpaceProvider::URI)
    rescue
      DRb.start_service(nil, TupleSpaceProvider.new)
    end
  end
end
