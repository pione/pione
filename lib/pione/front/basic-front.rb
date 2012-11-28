module Pione
  module Front
    # FrontError is raised when front server cannnot start.
    class FrontError < StandardError; end

    # This is base class for all PIONE front classes. PIONE fronts exist in each
    # command and control its process.
    class BasicFront < PioneObject
      include DRbUndumped
      extend Forwardable

      attr_reader :command
      attr_reader :uri
      attr_reader :attrs

      # Creates a front server as druby's service.
      def initialize(command, port)
        @command = command
        # @uri = start_service(port, {:verbose => true})
        @uri = start_service(port, {})
        @attrs = {}
      end

      # Returns the pid.
      def pid
        Process.pid
      end

      # Terminates the front.
      def terminate
        DRb.stop_service
      end

      private

      # Starts drb service and returns the URI.
      def start_service(port, config)
        if port.kind_of?(Range)
          port = port.each
          begin
            DRb.start_service("druby://%s:%s" % [Global.my_ip_address, port.next], self, config)
          rescue StopIteration => e
            raise FrontError.new("you couldn't start front server.")
          rescue
            retry
          end
        else
          begin
            DRb.start_service(port ? "druby://%s:%s" % [Global.my_ip_address, port] : nil, self, config)
          rescue => e
            raise FrontError.new("You couldn't start front server: %s" % e.message)
          end
        end
        return DRb.uri
      end
    end
  end
end
