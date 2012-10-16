module Pione
  module Front
    def self.get
      DRb.front
    end

    # This is base class for all PIONE front classes. PIONE fronts exist in each
    # command and control its process.
    class BasicFront < PioneObject
      # fronts are referred as remote objects
      include DRbUndumped

      # front URI
      attr_reader :uri

      # Creates a front server as druby's service.
      def initialize(port=nil)
        uri = port ? "druby://localhost:%s" % port : nil
        DRb.start_service(uri, self)
        @uri = DRb.uri
      end

      # Returns the pid.
      def pid
        Process.pid
      end

      # Starts front server.
      def start
        # do nothing
      end
    end
  end
end
