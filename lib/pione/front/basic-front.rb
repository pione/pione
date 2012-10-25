module Pione
  module Front
    # This is base class for all PIONE front classes. PIONE fronts exist in each
    # command and control its process.
    class BasicFront < PioneObject
      include DRbUndumped
      extend Forwardable

      attr_reader :command
      attr_reader :uri

      # Creates a front server as druby's service.
      def initialize(command, port)
        @command = command
        @uri = start_service(port)
      end

      # Returns the pid.
      def pid
        Process.pid
      end

      def terminate
        DRb.stop_service
      end

      private

      # Starts drb service and returns the URI.
      def start_service(port)
        DRb.start_service(port ? "druby://localhost:%s" % port : nil, self)
        return DRb.uri
      end
    end
  end
end
