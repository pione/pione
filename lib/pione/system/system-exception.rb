module Pione
  module System
    class SystemError < StandardError; end

    # PioneBug is an error that is caused by PIONE's bug.
    class PioneBug < SystemError
      def initialize(message)
        @message = message
      end

      def message
        "[PIONE BUG] " + @message
      end
    end

    class DomainDumpErro < SystemError; end
  end
end
