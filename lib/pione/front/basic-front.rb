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

      attr_reader :command
      attr_reader :uri

      # Creates a front server as druby's service.
      def initialize(command, port)
        @command = command
        uri = port ? "druby://localhost:%s" % port : nil
        DRb.start_service(uri, self)
        @uri = DRb.uri
      end

      # Returns the pid.
      def pid
        Process.pid
      end

      def terminate
        DRb.stop_service
      end
    end
  end

  def self.set_front(front)
    @front = front
  end

  def self.front
    @front
  end
end
