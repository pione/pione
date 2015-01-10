module Pione
  module Util
    # ProcessInfo is a class for watching or manipulating OS processes.
    class ProcessInfo < StructX
      member :pid
      member :thread

      forward! Proc.new{thread}, :alive?, :stop?

      # Kill the process. This method waits the process to be dead.
      #
      # @param signal [Symbol]
      #   the signal to send
      # @return [void]
      def kill(signal = :TERM)
        Process.kill(signal, pid)
        wait
      end

      # Wait until the process is dead.
      def wait
        thread.join
      end
    end
  end
end
