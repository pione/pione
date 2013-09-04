module Pione
  module Util
    module Misc
      # Ignores all exceptions of the block execution.
      # @yield []
      #   target block
      # @return [void]
      def ignore_exception(*exceptions, &b)
        exceptions = [Exception] if exceptions.empty?
        b.call
      rescue *exceptions => e
        ErrorReport.warn("the error ignored", nil, e, __FILE__, __LINE__)
        return false
      end

      # Returns the hostname of the machine.
      # @return [String]
      #   hostname
      def hostname
        Socket.gethostname
      end
    end

    extend Misc
  end
end
