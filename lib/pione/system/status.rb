module Pione
  module System
    class Status
      class << self
        def success
          new(:success)
        end

        def error(exception)
          new(:error, exception)
        end
      end

      attr_reader :exception

      def initialize(status, exception=nil)
        @status = status
        @exception = exception
      end

      def success?
        @status == :success
      end

      def error?
        @status == :error
      end
    end
  end
end
