module Pione
  module Front
    # This is base class for all PIONE front classes. PIONE fronts exist in each
    # command and behave as remote interface.
    class BasicFront < PioneObject
      include DRbUndumped

      attr_reader :uri   # front server's URI string
      attr_reader :attrs
      attr_reader :child # child process table

      # Creates a front server as druby's service.
      def initialize(port)
        @uri = start_service(port, {}) # port is number or range
        @attrs = {}
        @child = {}
      end

      # Return PID of the process.
      def pid
        Process.pid
      end

      def [](name)
        @attrs[name]
      end

      def []=(name, val)
        @attrs[name] = val
      end

      # Add child process.
      def add_child(pid, front_uri)
        @child[pid] = front_uri
      end

      # Delete child process.
      def remove_child(pid)
        @child.delete(pid)
      end

      # Terminate the front server. This method assumes to be not called from
      # other process. Note that front servers have no responsibility of killing
      # child processes.
      def terminate
        DRb.stop_service
      end

      # Terminate the command. This is a nonblocking method because callee
      # process cannot tell its termination to caller, so it returns true
      # immediately.
      def terminate_command
        Thread.new {Global.command.terminate}
        return true
      end

      private

      # Start DRb service and return the URI string.
      def start_service(port, config)
        if port.kind_of?(Range)
          enum = port.each
          begin
            DRb.start_service(build_front_server_uri(enum.next), self, config)
          rescue StopIteration => e
            raise FrontError.new(self, e)
          rescue
            retry
          end
        else
          DRb.start_service(build_front_server_uri(port), self, config)
        end

        return DRb.uri
      rescue => e
        raise FrontError.new(self, e)
      end

      # Build front server URI. Note that the address is configured by
      # +Global.my_ip_address+.
      def build_front_server_uri(port)
        "druby://%s:%s" % [Global.my_ip_address, port]
      end
    end
  end
end
