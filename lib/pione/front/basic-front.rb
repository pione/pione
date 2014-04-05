module Pione
  module Front
    # This is base class for all PIONE front classes. PIONE fronts exist in each
    # command and behave as remote control interface.
    class BasicFront < PioneObject
      include DRbUndumped

      attr_reader :uri   # front server's URI string

      # Creates a front server as druby's service.
      def initialize(cmd, port)
        @cmd = cmd
        @uri = URI.parse(start_service(port, {})) # port is number or range
        @attr = {}
        @child = {}
        @child_lock = Mutex.new
        @child_watchers = ThreadGroup.new
      end

      # Return PID of the process.
      def pid
        Process.pid
      end

      def [](name)
        @attr[name]
      end

      def []=(name, val)
        @attr[name] = val
      end

      # Register the process as a child of this process. It is unregistered when
      # the child is terminated.
      #
      # @param pid [String]
      #   child process's PID
      # @param front_uri [String]
      #   child process's front URI
      # @return [void]
      def register_child(pid, front_uri)
        unless @cmd.current_phase == :termination
          # register child's PID
          @child_lock.synchronize {@child[pid] = front_uri}

          # unregister automatically when the child is terminated
          thread = Thread.new do
            Util.ignore_exception(Errno::ECHILD) do
              Process.waitpid(pid)
              unregister_child(pid)
            end
          end
          thread[:pid] = pid
          @child_watchers.add(thread)

          return nil
        else
          raise ChildRegistrationError.new
        end
      end

      # Unregister the child process.
      #
      # @param pid [String]
      #   child's PID to be removed
      def unregister_child(pid)
        # unregister the pid
        @child_lock.synchronize {@child.delete(pid)}

        # kill the watcher thread
        @child_watchers.list.each do |thread|
          if thread[:pid] == pid
            thread.kill
            break
          end
        end
      end

      # Return list of child process's PIDs.
      #
      # @return [Array]
      #   list of child command's PIDs.
      def child_pids
        @child.keys
      end

      # Return a front URI of the child PID.
      #
      # @return [String]
      #   URI of the child PID
      def child_front_uri(pid)
        @child[pid]
      end

      def system_logger
        Log::SystemLog.logger
      end

      # Terminate the front server. This method assumes to be not called from
      # other processes. Note that front servers have no responsibility of
      # killing child processes.
      def terminate
        DRb.stop_service
      end

      # Terminate the command. This is a nonblocking method because callee
      # process cannot tell its termination to caller, so it returns true
      # immediately.
      def terminate_command
        Thread.new {@cmd.terminate}
        return true
      end

      private

      # Start DRb service and return the URI string.
      def start_service(port, config)
        if port.kind_of?(Range)
          enum = port.each
          begin
            DRb.start_service(build_uri(enum.next), self, config)
          rescue StopIteration => e
            raise
          rescue
            retry
          end
        else
          DRb.start_service(build_uri(port), self, config)
        end

        return DRb.uri
      rescue => e
        raise FrontServerError.new(self, e)
      end

      # This provides non blocking API.
      def non_blocking(&b)
        Thread.new {b.call}
        return nil
      end

      # Build front server URI. Note that the address is configured by
      # `Global.communication_address`.
      def build_uri(port)
        "druby://%s:%s" % [Global.communication_address, port]
      end
    end
  end
end
