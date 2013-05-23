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
        rescue Exception
          # do nothing
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
