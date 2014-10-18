module Pione
  module System
    class Status
      class << self
        def success
          new(:success)
        end

        def error(property={})
          new(:error, property)
        end
      end

      def initialize(status, property={})
        @status = status
        @property = property
      end

      def success?
        @status == :success
      end

      def error?
        @status == :error
      end

      def message
        @property[:message]
      end

      def exception
        @property[:exception]
      end
    end
  end
end
