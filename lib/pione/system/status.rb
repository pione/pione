module Pione
  module System
    class Status
      class << self
        def success
          new(:success)
        end

        def error(message)
          new(:error, message)
        end
      end

      attr_reader :message

      def initialize(status, message=nil)
        @status = status
        @message = message
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
