module InnocentWhite
  class TupleSpaceReceiver
    URI = "druby://localhost:54321"

    def self.instance
      begin
        DRbObject.new_with_uri(TupleSpaceProvider::URI)
      rescue
        obj = self.new
        DRb.start_service(URI, obj)
        return obj
      end
    end

    attr_reader :thread
    attr_reader :agents

    def initialize
      @thread = nil
      @agents = []
    end

    def regist(agent)
      @agents << agent
    end

    def receive(agent_type)
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
