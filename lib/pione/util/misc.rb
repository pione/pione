module Pione
  module Util
    module Misc
      # Ignores all exceptions of the block execution.
      # @yield []
      #   target block
      # @return [void]
      def ignore_exception(&b)
        begin
          b.call
        rescue Exception => e
          ErrorReport.warn("the error ignored", nil, e, __FILE__, __LINE__)
        end
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
