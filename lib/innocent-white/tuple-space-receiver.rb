require 'innocent-white/innocent-white-object'

module InnocentWhite
  class TupleSpaceReceiver < InnocentWhiteObject
    
    RECEIVER_URI = "druby://localhost:54321"

    # Return the receiver instance.
    def self.get(data={})
      uri = data.has_key?(:port) ? "druby://localhost:#{data[:port]}" : RECEIVER_URI
      begin
        obj = DRbObject.new_with_uri(uri)
        obj.uuid # check the receiver exists
        return obj
      rescue
        receiver = self.new(data)
        DRb.start_service(URI, receiver)
        return receiver
      end
    end

    attr_reader :thread
    attr_reader :agents

    def initialize
      @thread = nil
      @agents = []
      run
    end

    def register(agent)
      @agents << agent
    end

    def run
      @thread = Thread.new do
        loop do
          msg = @socket.recv(1024)
          provider = Marshal.load(msg)
          @agents.each do |agent|
            agent.catch(provider.tuple_spaces)
          end
        end
      end
    end
  end
end
